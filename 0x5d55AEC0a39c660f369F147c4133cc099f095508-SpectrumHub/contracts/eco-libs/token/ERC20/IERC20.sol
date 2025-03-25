// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import { ISelectorRoleControl } from "../../access/SelectorRoleControlUpgradeable.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IERC20Base is IERC20, IERC20Metadata, IERC20Errors {}

interface IEcoERC20Metadata is IERC20Base {}

interface IEcoERC20Base is IERC20Base, IERC20Permit {}

interface IERC20Stake is IERC20Base {
    function stake(uint256 value, address receiver) external payable;

    function unstake(uint256 value, address receiver) external;
}

interface IERC20Rebased is IERC20Stake {
    function totalShares() external view returns (uint256);

    function shareOf(address account) external view returns (uint256);

    function calcShare(uint256 balance) external view returns (uint256);

    function calcBalance(uint256 share) external view returns (uint256);
}

interface IWNative is IERC20Base {
    event Deposit(address indexed acc, uint256 amount);
    event Withdrawal(address indexed acc, uint256 amount);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    receive() external payable;
}

interface IWETH is IWNative {}

interface IERC20Burnable is IERC20Base {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IERC20Mintable is IERC20Burnable {
    function mint(address to, uint256 amount) external;
}

interface IEcoERC4626 is IERC20Burnable, IERC20Permit, IERC4626 {}

interface IEcoERC20Mintable is IERC20Mintable {}

interface IEcoERC20 is IEcoERC20Mintable, ISelectorRoleControl, IERC20Permit {}
