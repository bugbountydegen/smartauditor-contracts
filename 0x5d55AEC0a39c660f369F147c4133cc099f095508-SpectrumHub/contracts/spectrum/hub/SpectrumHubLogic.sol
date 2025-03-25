// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC20, IEcoERC20, IWETH } from "../../eco-libs/token/ERC20/IERC20.sol";

import { IKromaBridge } from "../../eco-libs/kroma/interfaces.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISpectrumHubState, SpectrumHubState } from "./SpectrumHubState.sol";
import { SpectrumHubUtils } from "./SpectrumHubUtils.sol";

interface ISpectrumHubLogic is ISpectrumHubState {
    event Stake(address indexed from, address indexed to, address indexed asset, uint256 assetAmount, uint256 spAmount);

    event Unstake(
        address indexed from,
        address indexed to,
        address indexed asset,
        uint256 assetAmount,
        uint256 spAmount
    );
}

abstract contract SpectrumHubLogic is ISpectrumHubLogic, SpectrumHubState, SpectrumHubUtils {
    struct HubParams {
        address from;
        address to;
        address asset;
        uint256 assetAmount;
        uint256 spAmount;
    }

    function _emitStake(HubParams memory p) internal {
        emit Stake(p.from, p.to, p.asset, p.assetAmount, p.spAmount);
    }

    function _emitUnstake(HubParams memory p) internal {
        emit Unstake(p.from, p.to, p.asset, p.assetAmount, p.spAmount);
    }

    function _switchConvertFunctionForStake(
        AssetID assetId
    ) internal pure returns (function(address, address, uint256) internal returns (uint256) assetActionFunction) {
        if (assetId == AssetID.ETH) return _convertETHToEETH;
        if (assetId == AssetID.EETH) return _convertEETHToWEETH;
        if (assetId == AssetID.WEETH) return _convertWEETHToSPETH;
        if (assetId == AssetID.WSTETH) return _convertWSTETHToSTETH;
        if (assetId == AssetID.STETH) return _convertSTETHToEETH;

        revert Spectrum(SpectrumErrors.Asset);
    }

    function _switchConvertFunctionForUnstake(
        AssetID assetId
    )
        internal
        pure
        returns (function(address, address, uint256, address) internal returns (uint256) assetActionFunction)
    {
        if (assetId == AssetID.SPETH) return _convertSPETHToWEETH;
        if (assetId == AssetID.WEETH) return _convertWEETHToEETH;

        revert Spectrum(SpectrumErrors.Asset);
    }

    function _assetConvertForStake(address asset, uint256 amount) internal returns (uint256 resultAmount) {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        Action memory thisAction = $.actionForStake[asset];

        resultAmount = _switchConvertFunctionForStake(thisAction.assetId)(asset, thisAction.actionTo, amount);
        if (thisAction.assetId == AssetID.WEETH) return resultAmount;
        resultAmount = _assetConvertForStake(thisAction.nextAsset, resultAmount);
    }

    function _assetConvertForUnstake(address asset, uint256 amount) internal returns (uint256 resultAmount) {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        Action memory thisAction = $.actionForUnstake[asset];

        resultAmount = _switchConvertFunctionForUnstake(thisAction.assetId)(
            asset,
            thisAction.actionTo,
            amount,
            thisAction.nextAsset
        );
        if (thisAction.assetId == AssetID.WEETH) return resultAmount;
        resultAmount = _assetConvertForUnstake(thisAction.nextAsset, resultAmount);
    }

    function _assetReceive(address asset, address from, uint256 amount) internal {
        if (asset == address(0)) {
            if (msg.value != amount) revert Spectrum(SpectrumErrors.Amount);
        } else {
            SafeERC20.safeTransferFrom(IERC20(asset), from, address(this), amount);
        }
    }

    function _assetTransfer(address asset, address to, uint256 amount) internal {
        if (asset == address(0)) {
            Address.sendValue(payable(to), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(asset), to, amount);
        }
    }

    function _bridge(address to, uint256 amount) internal {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        HubInfo memory info = $.info;
        if (info.bridge != address(0)) {
            IERC20(info.spETH).approve(info.bridge, amount);
            IKromaBridge(payable(info.bridge)).bridgeERC20To(info.spETH, info.l2spETH, to, amount, 200000, hex"");
        } else {
            _assetTransfer(info.spETH, to, amount);
        }
    }
}
