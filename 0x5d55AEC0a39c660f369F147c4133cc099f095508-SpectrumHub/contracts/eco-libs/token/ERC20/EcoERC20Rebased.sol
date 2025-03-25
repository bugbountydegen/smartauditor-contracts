// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ERC20RebasedUpgradeable } from "./ERC20RebasedUpgradeable.sol";
import { IERC20, IERC20Metadata } from "./IERC20.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EcoERC20RebasedWithToken is ERC20RebasedUpgradeable {
    function _totalSupply() internal view virtual override returns (uint256) {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        return IERC20($.underlying).balanceOf(address(this));
    }

    function _checkRebaseUnderlying(address _underlying) internal virtual override {
        if (_underlying == address(0)) revert InvalidInitialization();
        if (IERC20Metadata(_underlying).decimals() != decimals()) revert InvalidInitialization();
    }

    function _receiveUnderlying(uint256 value, address caller) internal virtual override {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        SafeERC20.safeTransferFrom(IERC20($.underlying), caller, address(this), value);
    }

    function _sendUnderlying(address receiver, uint256 value) internal virtual override {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        SafeERC20.safeTransfer(IERC20($.underlying), receiver, value);
    }
}

contract EcoERC20RebasedWithNative is ERC20RebasedUpgradeable {
    receive() external payable {}

    function _totalSupply() internal view virtual override returns (uint256) {
        return address(this).balance;
    }

    function _checkRebaseUnderlying(address _underlying) internal virtual override {
        if (_underlying != address(0)) revert InvalidInitialization();
        if (decimals() != 18) revert InvalidInitialization();
    }

    function _receiveUnderlying(uint256 value, address caller) internal virtual override {
        require(msg.value == value && _msgSender() == caller);
    }

    function _sendUnderlying(address receiver, uint256 value) internal virtual override {
        Address.sendValue(payable(receiver), value);
    }
}
