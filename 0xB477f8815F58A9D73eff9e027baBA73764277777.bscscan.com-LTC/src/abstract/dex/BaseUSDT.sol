// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";
import {_USDT, _ROUTER, _FACTORY} from "../../utils/constant.sol";

abstract contract BaseUSDT {
    address public immutable uniswapV2Pair;

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(_FACTORY).createPair(address(this), _USDT);
    }
}
