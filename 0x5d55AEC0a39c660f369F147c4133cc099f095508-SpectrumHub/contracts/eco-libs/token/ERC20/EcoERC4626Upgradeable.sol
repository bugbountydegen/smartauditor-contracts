// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { ERC20MetadataUpgradeable } from "./ERC20MetadataUpgradeable.sol";

import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import { IERC20, IERC20Metadata, IERC20Burnable, IERC20Permit, IEcoERC20, IEcoERC4626 } from "./IERC20.sol";

import { ERC20MetadataUpgradeable } from "./ERC20MetadataUpgradeable.sol";

contract EcoERC4626Upgradeable is
    IEcoERC4626,
    ERC20BurnableUpgradeable,
    ERC20MetadataUpgradeable,
    ERC20PermitUpgradeable,
    ERC4626Upgradeable
{
    function initEcoERC4626(IERC20 asset, string memory _name, string memory _symbol) public virtual initializer {
        _initEcoERC4626(asset, _name, _symbol);
    }

    function _initEcoERC4626(IERC20 asset, string memory _name, string memory _symbol) internal onlyInitializing {
        __ERC20Burnable_init();
        _initEcoERC20Metadata(_name, _symbol, decimals());
        __ERC20Permit_init(name());
        __ERC4626_init(IERC20(asset));
    }

    function name()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.name();
    }

    function symbol()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.symbol();
    }

    function decimals()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, ERC4626Upgradeable, IERC20Metadata)
        returns (uint8)
    {
        return super.decimals();
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 value) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        return super.transfer(to, value);
    }

    function allowance(
        address owner,
        address spender
    ) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 value) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable, IERC20Burnable) {
        super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override(ERC20BurnableUpgradeable, IERC20Burnable) {
        super.burnFrom(account, amount);
    }

    function nonces(
        address owner
    ) public view virtual override(ERC20PermitUpgradeable, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
