// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ISwapManager} from "src/interfaces/ISwapManager.sol";
import {BaseSwapManager} from "src/SwapManagers/BaseSwapManager.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "src/interfaces/ISwapRouter02.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniversalRouter} from "src/interfaces/IUniversalRouter.sol";
/**
 * @title UniswapV3SwapManager
 * @notice Swap manager implementation for Uniswapv3 pools
 * @notice The swap manager receives the sellToken but does not get back the buyToken which is sent to the recipient directly
 * @notice fallback swap solutions if Paraswap fails
 */
contract UniswapV3SwapManager is ISwapManager, BaseSwapManager {
    using SafeERC20 for IERC20;

    ISwapRouter public uniswapV3Router;
    IUniswapV3Factory public uniswapV3factory;
    // address public uniswapPermit2;

    constructor(address _uniswapV3Router, address _uniswapV3factory) {
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        uniswapV3factory = IUniswapV3Factory(_uniswapV3factory);
    }

    // /**
    //  * @dev Performs a Uniswap v3 exact input token swap.
    //  * @param _sellToken The address of the token to sell.
    //  * @param _buyToken The address of the token to buy.
    //  * @param _sellAmount The amount of the sell token to swap.
    //  * @param _minBuyAmount The minimum amount of the buy token to receive.
    //  * @param _data Data passed for the swap.
    //  * @return _buyAmount The amount of the buy token received from the swap.
    //  */
    function swap(
        address _sellToken,
        address _buyToken,
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        bytes calldata _data
    )
        public
        swapChecks(_sellToken, _buyToken, _sellAmount, _minBuyAmount)
        onlyDelegateCall
        returns (uint256)
    {
        SwapParams memory params;
        (params.router, params.recipient, params.sqrtPriceLimitX96) = abi
            .decode(_data, (address, address, uint160));

        params.sellToken = _sellToken;
        params.buyToken = _buyToken;
        params.sellAmount = _sellAmount;
        params.minBuyAmount = _minBuyAmount;

        ERC20(_sellToken).approve(params.router, _sellAmount);

        return _executeSwap(params);
    }

    struct SwapParams {
        address router;
        address sellToken;
        address buyToken;
        address recipient;
        uint256 sellAmount;
        uint256 minBuyAmount;
        uint160 sqrtPriceLimitX96;
    }

    function _executeSwap(SwapParams memory params) internal returns (uint256) {
        return
            ISwapRouter(params.router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: params.sellToken,
                    tokenOut: params.buyToken,
                    fee: _getSwapFee(params.sellToken, params.buyToken),
                    recipient: params.recipient,
                    amountIn: params.sellAmount,
                    amountOutMinimum: params.minBuyAmount,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );
    }

    /**
     * @notice Finds the pool fee tier for a given token par with the largest liquidity.
     * @param _sellToken The address of the token to sell.
     * @param _buyToken The address of the token to buy.
     * @return swapFee The fee tier of the pool with the largest liquidity.
     */

    function _getSwapFee(
        address _sellToken,
        address _buyToken
    ) internal view returns (uint24 swapFee) {
        address bestSwapPool;
        address tempPool;
        uint24[4] memory feeTiers = [
            uint24(100),
            uint24(500),
            uint24(3000),
            uint24(10000)
        ];
        for (uint256 i = 0; i < feeTiers.length; i++) {
            tempPool = uniswapV3factory.getPool(
                _sellToken,
                _buyToken,
                feeTiers[i]
            );

            // set initial value
            if (bestSwapPool == address(0) && tempPool != address(0)) {
                swapFee = feeTiers[i];
                bestSwapPool = tempPool;
            }
            if (
                // Skips is no pool exists for the given fee tier and token pair
                tempPool != address(0) &&
                IUniswapV3Pool(bestSwapPool).liquidity() <
                IUniswapV3Pool(tempPool).liquidity()
            ) {
                swapFee = feeTiers[i];
                bestSwapPool = tempPool;
            }
        }
    }
}
