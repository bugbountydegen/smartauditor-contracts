// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapManager {
    function swap(
        address _sellToken,
        address _buyToken,
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        bytes calldata _data
    ) external returns (uint256 _buyAmount);
}
