// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ISpectrumHubLogic, SpectrumHubLogic } from "./SpectrumHubLogic.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ISpectrumHubEntry is ISpectrumHubLogic {}

abstract contract SpectrumHubEntry is ISpectrumHubEntry, SpectrumHubLogic {
    using EnumerableSet for EnumerableSet.AddressSet;

    function stake(address asset, address to, uint256 assetAmount) public payable returns (uint256 spAmount) {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if (!$.supportAssetForStake.contains(asset)) revert Spectrum(SpectrumErrors.NotExist);

        HubParams memory params = HubParams({
            from: _msgSender(),
            to: to,
            asset: asset,
            assetAmount: assetAmount,
            spAmount: 0
        });

        _assetReceive(asset, params.from, params.assetAmount);

        params.spAmount = spAmount = _assetConvertForStake(asset, params.assetAmount);
        _emitStake(params);
        _bridge(to, params.spAmount);
    }

    function unstake(address asset, address to, uint256 spAmount) public returns (uint256 assetAmount) {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if ($.actionForUnstake[asset].assetId != AssetID.EETH) revert Spectrum(SpectrumErrors.Asset);

        HubParams memory params = HubParams({
            from: _msgSender(),
            to: to,
            asset: asset,
            assetAmount: 0,
            spAmount: spAmount
        });

        _assetReceive($.info.spETH, params.from, params.spAmount);

        params.assetAmount = assetAmount = _assetConvertForUnstake($.info.spETH, spAmount);
        _emitUnstake(params);
        _assetTransfer(asset, to, params.assetAmount);
    }
}
