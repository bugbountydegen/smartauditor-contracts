// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ISpectrumCoreLogic, SpectrumCoreLogic } from "./SpectrumCoreLogic.sol";
import { IstETH, IwstETH } from "../vendor/lido.sol";

interface ISpectrumCoreEntry is ISpectrumCoreLogic {
    function stake(address asset, address to, uint256 assetAmount) external returns (uint256 spAmount);

    function unstake(address asset, address to, uint256 spAmount) external returns (uint256 assetAmount);
}

abstract contract SpectrumCoreEntry is ISpectrumCoreEntry, SpectrumCoreLogic {
    function stake(
        address asset,
        address to,
        uint256 assetAmount
    ) public override onlyAdmin returns (uint256 spAmount) {
        SnapGlobal memory gSnap = getGlobalSnap();
        RequestParams memory reqParams;
        reqParams.asset = asset;
        reqParams.from = _msgSender();
        reqParams.to = to;
        reqParams.assetAmount = assetAmount;

        reqParams = _stake(gSnap, reqParams);

        return reqParams.spAmount;
    }

    function unstake(address asset, address to, uint256 spAmount) public override returns (uint256 assetAmount) {
        SnapGlobal memory gSnap = getGlobalSnap();
        RequestParams memory reqParams;
        reqParams.asset = asset;
        reqParams.from = _msgSender();
        reqParams.to = to;
        reqParams.spAmount = spAmount;

        reqParams = _unstake(gSnap, reqParams);

        return reqParams.assetAmount;
    }

    function evalSpectrum(uint256 spAmount) public view returns (uint256 ethValue) {
        SnapGlobal memory gSnap = getGlobalSnap();
        if (gSnap.info.spETH.totalSupply() == 0) revert Spectrum(SpectrumErrors.NotExist);
        ethValue = (gSnap.spSnap.evalValue * spAmount) / gSnap.info.spETH.totalSupply();
    }

    function getSpectrumFromETH(uint256 ethValue) public view returns (uint256 spAmount) {
        SnapGlobal memory gSnap = getGlobalSnap();
        spAmount = (gSnap.info.spETH.totalSupply() * ethValue) / gSnap.spSnap.evalValue;
    }

    function getSpectrumFromAsset(address asset, uint256 assetAmount) public view returns (uint256 spAmount) {
        spAmount = _getSpectrumFromAsset(getGlobalSnap(), asset, assetAmount);
    }

    function getAssetFromSpectrum(address asset, uint256 spAmount) public view returns (uint256 assetAmount) {
        assetAmount = _getAssetFromSpectrum(getGlobalSnap(), asset, spAmount);
    }
}
