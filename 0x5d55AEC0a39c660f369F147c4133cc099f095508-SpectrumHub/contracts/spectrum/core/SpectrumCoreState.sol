// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { SpectrumCommon } from "../common.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ISelectorRoleControl, SelectorRoleControlUpgradeable } from "../../eco-libs/access/SelectorRoleControlUpgradeable.sol";
import { IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";

interface ISpectrumCoreState is ISelectorRoleControl, SpectrumCommon {}

abstract contract SpectrumCoreState is ISpectrumCoreState, SelectorRoleControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct CoreInfo {
        IEcoERC20 spETH;
        address feeVault;
        uint96 defaultFeeAmount; // spAmount
    }

    struct CoreSupportAssetInfo {
        address assetEvaluator;
        AssetID id;
        // uint24 reserved;
        // uint64 reserved;
    }

    struct SpectrumCoreStorage {
        CoreInfo info;
        EnumerableSet.AddressSet supportAssets;
        mapping(address asset => CoreSupportAssetInfo) assetInfos;
    }

    // keccak256(abi.encode(uint256(keccak256("eco.storage.spectrum.core")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SpectrumCoreStorageLocation =
        0x8c137e051b200047b3ca65393a465e7f6ba7fbede12a786e4547d4e85a759900;

    function _getSpectrumCoreStorage() internal pure returns (SpectrumCoreStorage storage $) {
        assembly {
            $.slot := SpectrumCoreStorageLocation
        }
    }

    function setCoreInfo(CoreInfo memory info) public onlyAdmin {
        _getSpectrumCoreStorage().info = info;
    }

    function getCoreInfo() public view returns (CoreInfo memory) {
        return _getSpectrumCoreStorage().info;
    }

    function _checkAssetInfoNotEmpty(CoreSupportAssetInfo memory assetInfo) internal pure {
        if (assetInfo.assetEvaluator == address(0) || assetInfo.id == AssetID.None)
            revert Spectrum(SpectrumErrors.Data);
    }

    function addCoreSupportAsset(address asset, CoreSupportAssetInfo memory assetInfo) public onlyAdmin {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        if (!$.supportAssets.add(asset)) revert Spectrum(SpectrumErrors.Exist);
        _checkAssetInfoNotEmpty(assetInfo);
        $.assetInfos[asset] = assetInfo;
    }

    function removeCoreSupportAsset(address asset) public onlyAdmin {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        if (!$.supportAssets.remove(asset)) revert Spectrum(SpectrumErrors.NotExist);
        delete $.assetInfos[asset];
    }

    function updateCoreSupportAsset(address asset, CoreSupportAssetInfo memory assetInfo) public onlyAdmin {
        SpectrumCoreStorage storage $ = _getSpectrumCoreStorage();
        _checkAssetInfoNotEmpty(assetInfo);
        if (!$.supportAssets.contains(asset)) revert Spectrum(SpectrumErrors.NotExist);
        $.assetInfos[asset] = assetInfo;
    }

    function getCoreSupportAssetLists() public view returns (address[] memory) {
        return _getSpectrumCoreStorage().supportAssets.values();
    }
}
