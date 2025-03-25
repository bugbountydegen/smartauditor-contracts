// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract DegenUpLaunchpad is ERC20, Ownable {
    using SafeERC20 for ERC20;

    // Custom errors
    error InsufficientETHSent();
    error TradingFeeTransferFailed();
    error NotEnoughTokensForSale();
    error TokenBalanceTooLow();
    error InsufficientETHInContract();
    error FailedToSendETH();
    error BondingCurveNotReached();
    error NoTokensToClaim();
    error NoTokensAvailableForClaimingYet();
    error LiquidityAlreadyAdded();
    error LiquidityTransferFailed();
    error RemainingETHTransferFailed();
    error AllowanceTooLow();

    struct Purchase {
        uint256 totalTokens;
        uint256 claimedTokens;
        uint256 initialUnlockAmount;
        uint256 remainingVestingAmount;
        uint256 claimableAmount;
        uint256 lastClaimTime;
    }

    ERC20 public token = ERC20(address(this));
    uint256 public totalTokensSold;
    uint256 public totalEthDeposited;
    uint256 public bondingCurveGoal = 5.5 ether;
    bool public liquidityAdded;
    uint256 public constant VESTING_DURATION = 20 hours;
    uint256 public constant INITIAL_TOKEN_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant TOKENS_FOR_SALE = (INITIAL_TOKEN_SUPPLY * 80) / 100;
    uint256 public constant INITIAL_UNLOCK_PERCENTAGE = 50;
    uint256 public constant UNLOCK_RATE_PER_HOUR = 2.5 ether;
    uint256 public constant MIGRATION_FEE = 0.5 ether;
    uint256 public constant TRADING_FEE_PERCENTAGE = 1;
    uint256 public finalizedTime;

    // Bonding Curve parameters
    uint256 public constant INITIAL_VIRTUAL_COLLATERAL = 1.375 ether;
    address public INITIAL_OWNER = 0xb9e660505E8823F1c10Db4Be1D6D51953191234c;

    // Bonding curve formula x * y = k
    uint256 public constant k =
        INITIAL_VIRTUAL_COLLATERAL * INITIAL_TOKEN_SUPPLY; // k = 1.375 * 10^9

    mapping(address => Purchase) public purchases;

    // Track token holders
    mapping(address => uint256) public holderBalances;
    address[] public tokenHolders;

    // Uniswap router and factory addresses
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    // Internal constant Uniswap router address
    address internal constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Events
    event TokenTransaction(
        address indexed user,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 totalEthDeposited,
        uint256 totalTokensSold,
        uint256 timestamp,
        bool isPurchase
    );
    event TokensClaimed(address indexed claimer, uint256 amount);

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(INITIAL_OWNER) {
        _mint(address(this), INITIAL_TOKEN_SUPPLY);
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
    }

    // Modifier to check if bonding curve goal has been reached
    modifier bondingCurveComplete() {
        if (totalEthDeposited < bondingCurveGoal) {
            revert BondingCurveNotReached();
        }
        _;
    }

    // Purchase tokens based on bonding curve formula
    function buyTokens(address buyer) external payable {
        if (msg.value == 0) {
            revert InsufficientETHSent();
        }

        // Apply 1% trading fee
        uint256 tradingFee = (msg.value * TRADING_FEE_PERCENTAGE) / 100;
        uint256 ethAfterFee = msg.value - tradingFee;

        // Transfer the trading fee to the initialOwner wallet
        address initialOwner = owner(); // Retrieves the owner of the contract (initialOwner)
        (bool sent, ) = initialOwner.call{value: tradingFee}("");
        if (!sent) {
            revert TradingFeeTransferFailed();
        }

        uint256 tokensToReceive = getTokensForEth(ethAfterFee);
        uint256 remainingTokens = TOKENS_FOR_SALE - totalTokensSold;

        if (tokensToReceive > remainingTokens) {
            tokensToReceive = remainingTokens;
            uint256 ethRequired = bondingCurveGoal - totalEthDeposited;
            uint256 excessEth = ethAfterFee - ethRequired;

            // Refund the excess ETH to the buyer
            (bool refundSent, ) = buyer.call{value: excessEth}("");
            if (!refundSent) {
                revert FailedToSendETH();
            }

            ethAfterFee = ethRequired;
        }

        // Immediate unlock 50%
        uint256 initialUnlockAmount = (tokensToReceive *
            INITIAL_UNLOCK_PERCENTAGE) / 100;
        uint256 vestingAmount = tokensToReceive - initialUnlockAmount;

        // Update purchase data for cumulative vesting
        Purchase storage purchase = purchases[buyer];
        // Calculate claimable amount based on vesting schedule
        uint256 timePassed = block.timestamp - purchase.lastClaimTime;
        uint256 claimableTokens = getClaimableTokens(purchase, timePassed);
        purchase.claimableAmount += claimableTokens;

        purchase.totalTokens += tokensToReceive;
        purchase.claimedTokens += initialUnlockAmount;
        purchase.initialUnlockAmount += initialUnlockAmount;
        purchase.remainingVestingAmount += vestingAmount;
        purchase.lastClaimTime = block.timestamp;

        totalEthDeposited += ethAfterFee;
        totalTokensSold += tokensToReceive;

        // Transfer the 50% unlocked immediately
        token.safeTransfer(buyer, initialUnlockAmount);
        _updateHolderBalance(buyer, int256(initialUnlockAmount));
        emit TokenTransaction(
            buyer,
            tokensToReceive,
            ethAfterFee,
            totalEthDeposited,
            totalTokensSold,
            block.timestamp,
            true
        );

        // Check if bonding curve goal is reached and add liquidity
        if (totalEthDeposited >= bondingCurveGoal && !liquidityAdded) {
            addLiquidity();
        }
    }

    // Sell tokens and receive ETH based on the bonding curve
    function sellTokens(uint256 tokenAmount) external {
        if (tokenAmount == 0) {
            revert InsufficientETHSent();
        }
        if (balanceOf(msg.sender) < tokenAmount) {
            revert TokenBalanceTooLow();
        }

        // Check allowance
        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < tokenAmount) {
            revert AllowanceTooLow();
        }

        // Calculate the amount of ETH to return based on the bonding curve
        uint256 ethToReturn = getEthForTokens(tokenAmount);
        if (address(this).balance < ethToReturn) {
            revert InsufficientETHInContract();
        }

        // Apply 1% trading fee on ETH to be returned
        uint256 tradingFee = (ethToReturn * TRADING_FEE_PERCENTAGE) / 100;
        uint256 ethAfterFee = ethToReturn - tradingFee;

        // Transfer the trading fee to the initialOwner wallet
        address initialOwner = owner(); // Retrieves the owner of the contract (initialOwner)
        (bool sentFee, ) = initialOwner.call{value: tradingFee}("");
        if (!sentFee) {
            revert TradingFeeTransferFailed();
        }

        totalEthDeposited -= ethToReturn;
        totalTokensSold -= tokenAmount;

        // Transfer the tokens from the sender to the contract
        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        _updateHolderBalance(msg.sender, -int256(tokenAmount));

        // Transfer the ETH after fee to the user
        (bool sent, ) = msg.sender.call{value: ethAfterFee}("");
        if (!sent) {
            revert FailedToSendETH();
        }

        emit TokenTransaction(
            msg.sender,
            tokenAmount,
            ethToReturn,
            totalEthDeposited,
            totalTokensSold,
            block.timestamp,
            false
        );
    }

    // Function to claim vested tokens manually
    function claimVestedTokens() external {
        Purchase storage purchase = purchases[msg.sender];
        if (purchase.remainingVestingAmount == 0) {
            revert NoTokensToClaim();
        }

        uint256 timePassed = block.timestamp - purchase.lastClaimTime;
        uint256 claimableTokens = getClaimableTokens(purchase, timePassed);
        if (claimableTokens == 0) {
            revert NoTokensAvailableForClaimingYet();
        }

        // Update remaining vesting amount and last claim time
        purchase.remainingVestingAmount -= claimableTokens;
        purchase.claimedTokens += claimableTokens;
        purchase.claimableAmount = 0;
        purchase.lastClaimTime = block.timestamp;

        // Transfer the claimable tokens
        token.safeTransfer(msg.sender, claimableTokens);
        _updateHolderBalance(msg.sender, int256(claimableTokens));
        emit TokensClaimed(msg.sender, claimableTokens);
    }

    // Get claimable tokens based on time passed
    function getClaimableTokens(
        Purchase memory purchase,
        uint256 timePassed
    ) internal pure returns (uint256) {
        uint256 hoursPassed = timePassed / 1 hours;
        uint256 newClaimableAmount = (purchase.remainingVestingAmount *
            hoursPassed *
            UNLOCK_RATE_PER_HOUR) / 100 ether;
        if (newClaimableAmount > purchase.remainingVestingAmount) {
            newClaimableAmount = purchase.remainingVestingAmount;
        }
        purchase.claimableAmount += newClaimableAmount;
        return purchase.claimableAmount;
    }

    // Add liquidity to Uniswap after bonding curve goal is reached
    function addLiquidity() internal bondingCurveComplete {
        if (liquidityAdded) {
            revert LiquidityAlreadyAdded();
        }

        liquidityAdded = true;
        finalizedTime = block.timestamp; // Set the finalized time

        uint256 ethToWithdraw = totalEthDeposited - MIGRATION_FEE; // Account for migration fee
        uint256 tokensToWithdraw = 145_454_545 * 10 ** 18; // Based on your liquidity requirements

        // Approve Uniswap router to spend tokens
        token.approve(address(uniswapRouter), tokensToWithdraw);

        // Add liquidity to Uniswap
        (, , uint256 liquidity) = uniswapRouter.addLiquidityETH{
            value: ethToWithdraw
        }(
            address(token),
            tokensToWithdraw,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        );

        // Transfer remaining ETH to the owner
        uint256 remainingETH = address(this).balance;
        (bool success, ) = owner().call{value: remainingETH}("");
        if (!success) {
            revert RemainingETHTransferFailed();
        }

        // Burn the LP tokens
        address pair = uniswapFactory.getPair(
            address(token),
            uniswapRouter.WETH()
        );
        IUniswapV2Pair(pair).transfer(address(0), liquidity);

        // Revoke ownership of the contract
        _transferOwnership(address(0));
    }

    // Bonding curve logic: get the number of tokens for the amount of ETH sent
    function getTokensForEth(uint256 ethAmount) public view returns (uint256) {
        uint256 currentEthCollateral = totalEthDeposited +
            INITIAL_VIRTUAL_COLLATERAL;

        // Bonding curve: new supply = k / (current collateral + ethAmount)
        uint256 newEthCollateral = currentEthCollateral + ethAmount;
        uint256 newTokenSupply = k / newEthCollateral;

        // Existing token supply is based on the current collateral
        uint256 existingTokenSupply = k / currentEthCollateral;

        // Tokens to be purchased = existingTokenSupply - newTokenSupply
        uint256 tokens = existingTokenSupply - newTokenSupply;

        return tokens;
    }

    // Bonding curve logic: get the amount of ETH for the number of tokens
    function getEthForTokens(
        uint256 tokenAmount
    ) public view returns (uint256) {
        uint256 currentEthCollateral = totalEthDeposited +
            INITIAL_VIRTUAL_COLLATERAL;

        // Existing token supply is based on the current collateral
        uint256 existingTokenSupply = k / currentEthCollateral;
        // New token supply after selling tokens
        uint256 newTokenSupply = existingTokenSupply + tokenAmount;
        uint256 newEthCollateral = k / newTokenSupply;

        // Calculate ETH based on tokenAmount
        uint256 eth = currentEthCollateral - newEthCollateral;
        return eth;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Internal function to update holder balances
    function _updateHolderBalance(address holder, int256 amount) internal {
        if (amount > 0) {
            holderBalances[holder] += uint256(amount);
        } else {
            holderBalances[holder] -= uint256(-amount);
        }

        // Add to tokenHolders array if not already present
        if (holderBalances[holder] > 0 && !_isHolder(holder)) {
            tokenHolders.push(holder);
        }

        // Remove from tokenHolders array if balance is zero
        if (holderBalances[holder] == 0) {
            _removeHolder(holder);
        }
    }

    // Internal function to check if an address is a token holder
    function _isHolder(address holder) internal view returns (bool) {
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            if (tokenHolders[i] == holder) {
                return true;
            }
        }
        return false;
    }

    // Internal function to remove a holder from the tokenHolders array
    function _removeHolder(address holder) internal {
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            if (tokenHolders[i] == holder) {
                tokenHolders[i] = tokenHolders[tokenHolders.length - 1];
                tokenHolders.pop();
                break;
            }
        }
    }

    // Function to get token holders and their percentages
    function getTokenHoldersAndPercentages()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory holders = new address[](tokenHolders.length);
        uint256[] memory percentages = new uint256[](tokenHolders.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            holders[i] = tokenHolders[i];
            percentages[i] =
                (holderBalances[tokenHolders[i]] * 1e18) /
                TOKENS_FOR_SALE;
        }

        return (holders, percentages);
    }

    // New function to get bonding curve progress details
    function getBondingCurveProgress()
        external
        view
        returns (
            uint256 totalEthDeposited_,
            uint256 remainingEthToReachBondingCurve,
            uint256 remainingTokensForSale,
            uint256 bondingCurvePercentage,
            uint256 finalizedTime_
        )
    {
        totalEthDeposited_ = totalEthDeposited;
        remainingEthToReachBondingCurve = bondingCurveGoal - totalEthDeposited;
        remainingTokensForSale = TOKENS_FOR_SALE - totalTokensSold;
        bondingCurvePercentage = (totalEthDeposited * 1e18) / bondingCurveGoal;
        finalizedTime_ = finalizedTime;

        return (
            totalEthDeposited_,
            remainingEthToReachBondingCurve,
            remainingTokensForSale,
            bondingCurvePercentage,
            finalizedTime_
        );
    }

    // New function to get user's token balance, locked token amount, and claimable token amount
    function getUserTokenDetails(
        address user
    )
        external
        view
        returns (
            uint256 userBalance,
            uint256 lockedTokens,
            uint256 claimableTokens
        )
    {
        userBalance = balanceOf(user);
        Purchase memory purchase = purchases[user];
        lockedTokens = purchase.remainingVestingAmount;
        uint256 timePassed = block.timestamp - purchase.lastClaimTime;
        claimableTokens = getClaimableTokens(purchase, timePassed);

        return (userBalance, lockedTokens, claimableTokens);
    }
}
