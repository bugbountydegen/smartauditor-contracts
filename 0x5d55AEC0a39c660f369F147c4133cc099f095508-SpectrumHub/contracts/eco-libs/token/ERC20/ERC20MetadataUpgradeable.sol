// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { IEcoERC20Metadata, IERC20Metadata } from "./IERC20.sol";

abstract contract ERC20MetadataUpgradeable is IEcoERC20Metadata, ERC20Upgradeable {
    // keccak256(abi.encode(uint256(keccak256("eco.storage.ERC20MetadataUpgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20MetadataUpgradeableStorageLocation =
        0x5bacbea0cd534f9867e3a5c99fe0e401e8856261242468f24aa4869ec40ac300;

    struct ERC20MetadataUpgradeableStorage {
        string name;
        string symbol;
        uint8 decimals;
    }

    function _getERC20MetadataUpgradeableStorage() private pure returns (ERC20MetadataUpgradeableStorage storage $) {
        assembly {
            $.slot := ERC20MetadataUpgradeableStorageLocation
        }
    }

    function _initEcoERC20Metadata(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal onlyInitializing {
        ERC20MetadataUpgradeableStorage storage $ = _getERC20MetadataUpgradeableStorage();
        $.name = _name;
        $.symbol = _symbol;
        $.decimals = _decimals;
        __ERC20_init("", "");
    }

    function name() public view virtual override(ERC20Upgradeable, IERC20Metadata) returns (string memory) {
        return _getERC20MetadataUpgradeableStorage().name;
    }

    function symbol() public view virtual override(ERC20Upgradeable, IERC20Metadata) returns (string memory) {
        return _getERC20MetadataUpgradeableStorage().symbol;
    }

    function decimals() public view virtual override(ERC20Upgradeable, IERC20Metadata) returns (uint8) {
        return _getERC20MetadataUpgradeableStorage().decimals;
    }
}
