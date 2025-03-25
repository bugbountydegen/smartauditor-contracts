// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { SpectrumCommon } from "../common.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ISelectorRoleControl, SelectorRoleControlUpgradeable } from "../../eco-libs/access/SelectorRoleControlUpgradeable.sol";
import { IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";

interface ISpectrumHubState is ISelectorRoleControl, SpectrumCommon {}

abstract contract SpectrumHubState is ISpectrumHubState, SelectorRoleControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct HubInfo {
        address bridge;
        address spETH;
        address l2spETH;
    }

    struct Action {
        AssetID assetId;
        // uint88 reserved;
        address actionTo;
        address nextAsset;
    }

    struct SpectrumHubStorage {
        HubInfo info;
        EnumerableSet.AddressSet supportAssetForStake;
        mapping(address => Action) actionForStake;
        EnumerableSet.AddressSet supportAssetForUnstake;
        mapping(address => Action) actionForUnstake;
    }

    // keccak256(abi.encode(uint256(keccak256("eco.storage.spectrum.hub")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SpectrumHubStorageLocation =
        0xb0b439de8d47439e35f983f1b3239e3509479aa5b7772b24605dca0595446000;

    function _getSpectrumHubStorage() internal pure returns (SpectrumHubStorage storage $) {
        assembly {
            $.slot := SpectrumHubStorageLocation
        }
    }

    function setHubInfo(HubInfo memory info) public onlyAdmin {
        _getSpectrumHubStorage().info = info;
    }

    function getHubInfo() public view returns (HubInfo memory) {
        return _getSpectrumHubStorage().info;
    }

    function _checkAssetInfoNotEmpty(Action memory assetInfo) internal pure {
        if (assetInfo.assetId == AssetID.None) revert Spectrum(SpectrumErrors.Data);
    }

    function getHubStakeAssetLists() public view returns (address[] memory) {
        return _getSpectrumHubStorage().supportAssetForStake.values();
    }

    function addHubStakeAsset(address asset, Action memory assetInfo) public onlyAdmin {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if (!$.supportAssetForStake.add(asset)) revert Spectrum(SpectrumErrors.Exist);
        _checkAssetInfoNotEmpty(assetInfo);
        $.actionForStake[asset] = assetInfo;
    }

    function removeHubStakeAsset(address asset) public onlyAdmin {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if (!$.supportAssetForStake.remove(asset)) revert Spectrum(SpectrumErrors.NotExist);
        delete $.actionForStake[asset];
    }

    function getHubUnstakeAssetLists() public view returns (address[] memory) {
        return _getSpectrumHubStorage().supportAssetForUnstake.values();
    }

    function addHubUnstakeAsset(address asset, Action memory assetInfo) public onlyAdmin {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if (!$.supportAssetForUnstake.add(asset)) revert Spectrum(SpectrumErrors.Exist);
        _checkAssetInfoNotEmpty(assetInfo);
        $.actionForUnstake[asset] = assetInfo;
    }

    function removeHubUnstakeAsset(address asset) public onlyAdmin {
        SpectrumHubStorage storage $ = _getSpectrumHubStorage();
        if (!$.supportAssetForUnstake.remove(asset)) revert Spectrum(SpectrumErrors.NotExist);
        delete $.actionForUnstake[asset];
    }
}
