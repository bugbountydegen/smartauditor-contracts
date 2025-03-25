// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ISelectorRoleControl, IPausable, IEcoOwnable, SelectorRoleControlUpgradeable } from "../../access/SelectorRoleControlUpgradeable.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

import { IERC20, IERC20Metadata, IERC20Burnable, IERC20Permit, IEcoERC20 } from "./IERC20.sol";

import { ERC20MetadataUpgradeable } from "./ERC20MetadataUpgradeable.sol";
import { EcoERC20MintableUpgradeable } from "./EcoERC20MintableUpgradeable.sol";

contract EcoERC20Upgradeable is
    IEcoERC20,
    ERC20MetadataUpgradeable,
    EcoERC20MintableUpgradeable,
    ERC20PermitUpgradeable
{
    function initEcoERC20(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public virtual initializer {
        _initEcoERC20Mintable(initialOwner, _name, _symbol, _decimals);
        __ERC20Permit_init(name());
    }

    function name()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20Metadata, ERC20MetadataUpgradeable, EcoERC20MintableUpgradeable)
        returns (string memory)
    {
        return super.name();
    }

    function symbol()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20Metadata, ERC20MetadataUpgradeable, EcoERC20MintableUpgradeable)
        returns (string memory)
    {
        return super.symbol();
    }

    function decimals()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20Metadata, ERC20MetadataUpgradeable, EcoERC20MintableUpgradeable)
        returns (uint8)
    {
        return super.decimals();
    }

    function burn(uint256 amount) public virtual override(EcoERC20MintableUpgradeable, IERC20Burnable) {
        super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override(EcoERC20MintableUpgradeable, IERC20Burnable) {
        super.burnFrom(account, amount);
    }

    function totalSupply() public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 value) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        return super.transfer(to, value);
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
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

    function nonces(
        address owner
    ) public view virtual override(ERC20PermitUpgradeable, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
