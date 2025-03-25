// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import { IERC20, IWNative, IWETH } from "./IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract WrappingNativeCoin is IWNative, ERC20Upgradeable, ERC20BurnableUpgradeable {
    constructor(string memory name, string memory symbol) {
        initWrappingNativeCoin(name, symbol);
    }

    function initWrappingNativeCoin(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable override {
        _mint(_msgSender(), msg.value);
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint256 amount) public override {
        _burn(_msgSender(), amount);
        emit Withdrawal(_msgSender(), amount);
        Address.sendValue(payable(_msgSender()), amount);
    }
}

contract WETH is IWETH, WrappingNativeCoin {
    constructor() WrappingNativeCoin("Wrapped Ether", "WETH") {}
}
