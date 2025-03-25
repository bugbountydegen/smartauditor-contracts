// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import { IERC20, IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";
import { IWETH, WrappingNativeCoin } from "../../eco-libs/token/ERC20/WETH.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IEcoUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IRewardsCollector {
    function collectRewards(bytes calldata looksRareClaim) external;
}

interface IUniversalRouter is IRewardsCollector, IERC721Receiver, IERC1155Receiver {
    error ExecutionFailed(uint256 commandIndex, bytes message);
    error ETHNotAccepted();
    error TransactionDeadlinePassed();
    error LengthMismatch();

    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}

interface IMockSwap is IEcoUniswapV3Router {}

contract MockSwap is IMockSwap {
    IEcoERC20 a;
    IEcoERC20 b;

    function setToken(IEcoERC20 _a, IEcoERC20 _b) public {
        a = _a;
        b = _b;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut) {
        require(0 < params.amountIn, "wstETH: zero amount unwrap not allowed");
        // TODO: check in/out token path !!!

        a.transferFrom(msg.sender, address(this), params.amountIn);
        amountOut = params.amountIn;
        require(params.amountOutMinimum <= amountOut, "mock swap minimum");
        b.transfer(msg.sender, amountOut);
    }

    function execute(bytes calldata, bytes[] calldata inputs, uint256) external payable {
        /// !!! mock logic !!!

        (address receiver, uint256 inAmount, uint256 outMinAmount, bytes memory path, bool transfer) = abi.decode(
            inputs[0],
            (address, uint256, uint256, bytes, bool)
        );

        if (transfer) a.transferFrom(msg.sender, address(this), inAmount);
        b.transfer(msg.sender, inAmount);
    }
}
