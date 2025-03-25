// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum OrderStatus {
    NOT_PROCESSED,
    FILLED,
    CANCELED
}

struct LimitOrder {
    address owner; // order owner olarak tekrardan isimlendir
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0;
    uint256 amount1;
    uint256 tokenId;
    uint128 liquidity;
    bool zeroForOne;
}

library LibLimitOrder {
    bytes32 constant LIMIT_ORDER_TYPEHASH =
        keccak256(
            "LimitOrder(address owner,address token0,address token1,uint24 fee,int24 tickLower,int24 tickUpper,uint256 amount0,uint256 amount1,uint256 tokenId)"
        );

    bytes32 constant BYTES32_TYPEHASH = keccak256("Root(bytes32 root)");

    function hash(LimitOrder memory limitOrder) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LIMIT_ORDER_TYPEHASH,
                    limitOrder.owner,
                    limitOrder.token0,
                    limitOrder.token1,
                    limitOrder.fee,
                    limitOrder.tickLower,
                    limitOrder.tickUpper,
                    limitOrder.tokenId
                )
            );
    }

    function hashBytes32(bytes32 root) internal pure returns (bytes32) {
        return keccak256(abi.encode(BYTES32_TYPEHASH, root));
    }
}
