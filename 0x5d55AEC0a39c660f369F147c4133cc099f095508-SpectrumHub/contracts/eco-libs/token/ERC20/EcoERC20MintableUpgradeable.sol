// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ISelectorRoleControl, IPausable, IEcoOwnable, SelectorRoleControlUpgradeable } from "../../access/SelectorRoleControlUpgradeable.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import { IERC20Metadata, IERC20Burnable, IEcoERC20Mintable } from "./IERC20.sol";

import { ERC20MetadataUpgradeable } from "./ERC20MetadataUpgradeable.sol";

abstract contract EcoERC20MintableUpgradeable is
    IEcoERC20Mintable,
    SelectorRoleControlUpgradeable,
    ERC20Upgradeable,
    ERC20MetadataUpgradeable,
    ERC20BurnableUpgradeable
{
    function _initEcoERC20Mintable(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal onlyInitializing {
        _initEcoOwnable(initialOwner); // SelectorRoleControlUpgradeable
        _initEcoERC20Metadata(_name, _symbol, _decimals);
        __ERC20Burnable_init();
    }

    function mint(address to, uint256 amount) public virtual override onlyAdmin {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual override(IERC20Burnable, ERC20BurnableUpgradeable) {
        return super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override(IERC20Burnable, ERC20BurnableUpgradeable) {
        return super.burnFrom(account, amount);
    }

    function name()
        public
        view
        virtual
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.name();
    }

    function symbol()
        public
        view
        virtual
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.symbol();
    }

    function decimals()
        public
        view
        virtual
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (uint8)
    {
        return super.decimals();
    }
}
