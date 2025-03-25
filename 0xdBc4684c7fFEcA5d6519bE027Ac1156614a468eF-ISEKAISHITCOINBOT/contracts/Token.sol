// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ISEKAISHITCOINBOT is ERC20 {
    constructor() ERC20("I Got Reincarnated As A Shitcoin And Everyone Is A Taxcoin Except For Me", "ISEKAISHITCOINBOT") {
        _mint(msg.sender, 666_666_666 * 10**18);
    }
}
