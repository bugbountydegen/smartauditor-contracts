// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";

interface CurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface YearnVault {
    function withdraw() external returns (uint256);
}

contract YVUSDCSwapper is ISwapper {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;
    CurvePool public constant MIM3POOL = CurvePool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    IERC20 public constant TETHER = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); 
    YearnVault public constant USDC_VAULT = YearnVault(0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    constructor(
        IBentoBoxV1 bentoBox_
    ) public {
        bentoBox = bentoBox_;
        USDC.approve(address(MIM3POOL), type(uint256).max);
    }


    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {

        bentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

        uint256 amountFrom = USDC_VAULT.withdraw();

        uint256 amountTo = MIM3POOL.exchange_underlying(2, 0, amountFrom, 0, address(bentoBox));

        (, shareReturned) = bentoBox.deposit(toToken, address(bentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (1,1);
    }
}
