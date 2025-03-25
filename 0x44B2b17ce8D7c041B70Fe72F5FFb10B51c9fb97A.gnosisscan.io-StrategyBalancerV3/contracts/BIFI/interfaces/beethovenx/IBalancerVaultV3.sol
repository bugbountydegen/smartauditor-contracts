   // SPDX-License-Identifier: MIT
   pragma solidity ^0.8.0;
   
   interface IBalancerVaultV3 {

    enum AddLiquidityKind {
        PROPORTIONAL,
        UNBALANCED,
        SINGLE_TOKEN_EXACT_OUT,
        DONATION,
        CUSTOM
    }

    struct AddLiquidityParams {
        address pool;
        address to;
        uint256[] maxAmountsIn;
        uint256 minBptAmountOut;
        AddLiquidityKind kind;
        bytes userData;
    }

    function addLiquidity(
        AddLiquidityParams memory params
    ) external returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData);

    function unlock(bytes calldata data) external returns (bytes memory result);
    function settle(address token, uint256 amountHint) external returns (uint256 credit);
   }
