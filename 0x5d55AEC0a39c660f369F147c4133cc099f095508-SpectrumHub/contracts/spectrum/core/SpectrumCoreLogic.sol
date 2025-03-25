// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC20, IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";

import { IKromaBridge } from "../../eco-libs/kroma/interfaces.sol";
import { IUniversalRouter } from "../vendor/uniswap.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISpectrumCoreState, SpectrumCoreState } from "./SpectrumCoreState.sol";
import { SpectrumCoreUtils } from "./SpectrumCoreUtils.sol";

import { IstETH } from "../vendor/lido.sol";

interface ISpectrumCoreLogic is ISpectrumCoreState {
    error InsufficientLiqudity(address asset, uint256 liquidity, uint256 variable);

    event Stake(
        address indexed indexedAsset,
        address indexed from,
        address indexed to,
        uint256 assetAmount,
        uint256 spAmount,
        uint256 fee
    );

    event Unstake(
        address indexed indexedAsset,
        address indexed from,
        address indexed to,
        uint256 assetAmount,
        uint256 spAmount,
        uint256 fee
    );
}

abstract contract SpectrumCoreLogic is ISpectrumCoreLogic, SpectrumCoreState, SpectrumCoreUtils {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IEcoERC20;

    struct SnapAsset {
        uint256 evalValue;
    }

    struct RequestParams {
        address asset;
        address from;
        address to;
        uint256 assetAmount;
        uint256 spAmount;
        uint256 feeAmount;
    }

    struct SnapGlobal {
        CoreInfo info;
        SnapAsset spSnap;
        address[] assets;
        SnapAsset[] snaps;
    }

    function _switchAssetEval(
        AssetID id
    ) internal pure returns (function(address, uint256) internal view returns (uint256)) {
        if (id == AssetID.WEETH) return _evalWEETH;
        revert Spectrum(SpectrumErrors.Function);
    }

    function _switchAssetAmountFromValue(
        AssetID id
    ) internal pure returns (function(address, uint256) internal view returns (uint256)) {
        if (id == AssetID.WEETH) return _getWEETHFromETH;
        revert Spectrum(SpectrumErrors.Function);
    }

    function getGlobalSnap() public view returns (SnapGlobal memory gSnap) {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        gSnap.info = $.info;
        gSnap.assets = $.supportAssets.values();
        gSnap.snaps = new SnapAsset[](gSnap.assets.length);

        unchecked {
            CoreSupportAssetInfo memory assetInfo;
            for (uint256 i; i < gSnap.snaps.length; i++) {
                assetInfo = $.assetInfos[gSnap.assets[i]];
                gSnap.snaps[i].evalValue = _switchAssetEval(assetInfo.id)(
                    assetInfo.assetEvaluator,
                    IEcoERC20(gSnap.assets[i]).balanceOf(address(this))
                );
                gSnap.spSnap.evalValue += gSnap.snaps[i].evalValue;
            }
        }
    }

    function _receiveAsset(RequestParams memory reqParams) internal {
        SafeERC20.safeTransferFrom(IERC20(reqParams.asset), reqParams.from, address(this), reqParams.assetAmount);
    }

    function _sendAsset(RequestParams memory reqParams) internal {
        SafeERC20.safeTransfer(IERC20(reqParams.asset), reqParams.to, reqParams.assetAmount);
    }

    function _evalStakeRequest(
        SnapGlobal memory gSnap,
        RequestParams memory reqParams
    ) internal view returns (RequestParams memory) {
        if (reqParams.from == address(0) || reqParams.to == address(0)) revert Spectrum(SpectrumErrors.Address);

        if (reqParams.assetAmount == 0 && reqParams.spAmount == 0) revert Spectrum(SpectrumErrors.Amount);
        else if (reqParams.assetAmount == 0)
            reqParams.assetAmount = _getAssetFromSpectrum(gSnap, reqParams.asset, reqParams.spAmount);
        else {
            reqParams.spAmount = _getSpectrumFromAsset(gSnap, reqParams.asset, reqParams.assetAmount);
        }

        return reqParams;
    }

    function _evalUnstakeRequest(
        SnapGlobal memory gSnap,
        RequestParams memory reqParams
    ) internal view returns (RequestParams memory) {
        if (reqParams.from == address(0) || reqParams.to == address(0)) revert Spectrum(SpectrumErrors.Address);
        if (reqParams.feeAmount == 0) reqParams.feeAmount = gSnap.info.defaultFeeAmount;

        if (reqParams.assetAmount == 0 && reqParams.spAmount == 0) revert Spectrum(SpectrumErrors.Amount);
        else if (reqParams.assetAmount == 0) {
            reqParams.assetAmount = _getAssetFromSpectrum(
                gSnap,
                reqParams.asset,
                reqParams.spAmount - reqParams.feeAmount
            );
        } else {
            reqParams.spAmount = _getSpectrumFromAsset(gSnap, reqParams.asset, reqParams.assetAmount);
            reqParams.spAmount += reqParams.feeAmount;
        }

        return reqParams;
    }

    function _stake(SnapGlobal memory gSnap, RequestParams memory reqParams) internal returns (RequestParams memory) {
        if (reqParams.assetAmount == 0 || reqParams.spAmount == 0) reqParams = _evalStakeRequest(gSnap, reqParams);

        _receiveAsset(reqParams);
        gSnap.info.spETH.mint(reqParams.to, reqParams.spAmount);
        _emitStake(reqParams);

        return reqParams;
    }

    function _unstake(SnapGlobal memory gSnap, RequestParams memory reqParams) internal returns (RequestParams memory) {
        if (reqParams.assetAmount == 0 || reqParams.spAmount == 0) reqParams = _evalUnstakeRequest(gSnap, reqParams);

        gSnap.info.spETH.burnFrom(reqParams.from, reqParams.spAmount);
        gSnap.info.spETH.mint(gSnap.info.feeVault, reqParams.feeAmount);
        _sendAsset(reqParams);
        _emitUnstake(reqParams);

        return reqParams;
    }

    function _getSpectrumFromAsset(
        SnapGlobal memory gSnap,
        address asset,
        uint256 assetAmount
    ) internal view returns (uint256 spAmount) {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        if (!$.supportAssets.contains(asset)) revert Spectrum(SpectrumErrors.NotExist);
        CoreSupportAssetInfo memory assetInfo = $.assetInfos[asset];
        uint256 spTotalSupply = gSnap.info.spETH.totalSupply();
        if (spTotalSupply == 0) return assetAmount;
        spAmount =
            (spTotalSupply * _switchAssetEval(assetInfo.id)(assetInfo.assetEvaluator, assetAmount)) /
            gSnap.spSnap.evalValue;
    }

    function _getAssetFromSpectrum(
        SnapGlobal memory gSnap,
        address asset,
        uint256 spAmount
    ) internal view returns (uint256 assetAmount) {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        if (!$.supportAssets.contains(asset)) revert Spectrum(SpectrumErrors.NotExist);
        CoreSupportAssetInfo memory assetInfo = $.assetInfos[asset];

        assetAmount = _switchAssetAmountFromValue(assetInfo.id)(
            assetInfo.assetEvaluator,
            (spAmount * gSnap.spSnap.evalValue) / gSnap.info.spETH.totalSupply()
        );
    }

    function _emitStake(RequestParams memory reqParams) internal {
        emit Stake(
            reqParams.asset,
            reqParams.from,
            reqParams.to,
            reqParams.assetAmount,
            reqParams.spAmount,
            reqParams.feeAmount
        );
    }

    function _emitUnstake(RequestParams memory reqParams) internal {
        emit Unstake(
            reqParams.asset,
            reqParams.from,
            reqParams.to,
            reqParams.assetAmount,
            reqParams.spAmount,
            reqParams.feeAmount
        );
    }
}
