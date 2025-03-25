// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapManager} from "src/interfaces/ISwapManager.sol";

/**
 * @title BaseSwapManager
 * @notice Base contract for swap managers
 * @notice The swap manager receives the sellToken but does not get back the buyToken which is sent to the recipient directly
 */
abstract contract BaseSwapManager {
    using SafeERC20 for IERC20;

    address immutable SELF;

    uint256 actualBought;
    uint256 actualSold;

    error InsufficientOutput();
    error InsufficientInput();
    error InvalidInput();
    error OnlyDelegateCall();
    error TooMuchInput();
    error SwapFailed();

    constructor() {
        SELF = address(this);
    }

    /**
     * @notice Modifier to restrict functions to be called only via delegate call.
     * @dev Reverts if the function is called directly (not via delegate call).
     */
    modifier onlyDelegateCall() {
        if (address(this) == SELF) {
            revert OnlyDelegateCall();
        }
        _;
    }

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _sellToken The address of the input token.
     * @param _buyToken The address of the output token.
     * @param _sellAmount The amount of input tokens to swap.
     * @param _minBuyAmount The minimum amount of output tokens to receive.
     */
    modifier swapChecks(
        address _sellToken,
        address _buyToken,
        uint256 _sellAmount,
        uint256 _minBuyAmount
    ) {
        uint256 sellTokenBalance = ERC20(_sellToken).balanceOf(address(this));
        if (sellTokenBalance < _sellAmount) revert InsufficientInput();
        uint256 buyTokenBalanceBefore = ERC20(_buyToken).balanceOf(
            address(this)
        );
        _;
        uint256 buyTokenBalanceAfter = ERC20(_buyToken).balanceOf(
            address(this)
        );
        actualBought = buyTokenBalanceAfter - buyTokenBalanceBefore;
        if (actualBought < _minBuyAmount) revert InsufficientOutput();
    }

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _sellToken The address of the input token.
     * @param _buyToken The address of the output token.
     * @param _buyAmount The amount of output tokens to expect.
     * @param _maxIn The max amount of input tokens to send.
     */
    modifier swapChecksExactOutput(
        address _sellToken,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _maxIn
    ) {
        uint256 sellTokenBalance = ERC20(_sellToken).balanceOf(address(this));
        uint256 buyTokenBalanceBefore = ERC20(_buyToken).balanceOf(
            address(this)
        );
        _;
        uint256 buyTokenBalanceAfter = ERC20(_buyToken).balanceOf(
            address(this)
        );
        actualBought = buyTokenBalanceAfter - buyTokenBalanceBefore;
        if (actualBought != _buyAmount) revert InsufficientOutput();
        actualSold =
            sellTokenBalance -
            ERC20(_sellToken).balanceOf(address(this));
        if (actualSold > _maxIn) revert TooMuchInput();
    }
}
