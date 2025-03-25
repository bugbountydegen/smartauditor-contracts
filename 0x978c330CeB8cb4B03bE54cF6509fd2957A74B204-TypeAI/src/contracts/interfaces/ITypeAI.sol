// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @author Raj Mazumder <rajmazumder27.08.2001@gmail.com>
/// @title Interface of Type AI Staking Pool with fixed APY and lockup.
interface ITypeAI {
    /// @notice Details of the stake holder.
    struct StakeHolder {
        /// @param wallet The address of the stake holder.
        address wallet;
        /// @param amount The total amount stake holder deposited.
        uint256 amount;
        /// @param claimableInterest The claimable interest of the stake holder.
        uint256 claimableInterest;
        /// @param realizedETH The realized ETH for the stake holder.
        uint256 realizedETH;
        /// @param unrealizedETH The unrealized ETH for the stake holder.
        uint256 unrealizedETH;
        /// @param stakedOn The timestamp when stake holder staked.
        uint256 stakedOn;
        /// @param aprStartedOn The timestamp when last apr started.
        uint256 aprStartedOn;
    }

    /// READ METHODS ///
    /**
     * @notice Returns the no of stake holders currently staked.
     * @return count The count of the stake holders.
     */
    function noOfStakeHolders() external view returns (uint256 count);

    /**
     * @notice Returns the stake holders addresses currently staked.
     * @return holders The stake holder addresses.
     */
    function getStakeHolders() external view returns (address[] memory holders);

    /**
     * @notice Returns the details about the `_stakeHolder`.
     * @param _stakeHolder address of the stake holder.
     * @return details The details about the `_stakeHolder`.
     */
    function stakeHolderDetailsOf(
        address _stakeHolder
    ) external view returns (StakeHolder memory details);

    /**
     * @notice Returns the total amount staked by `stakeHolder`.
     * @param stakeHolder address of the stake holder.
     * @return stakedAmount the total amount staked.
     */
    function totalAmountStakedBy(
        address stakeHolder
    ) external view returns (uint256 stakedAmount);

    /**
     * @notice Returns the total amount locked on the contract.
     * @return tvl the total amount of tokens locked.
     */
    function totalValueLocked() external view returns (uint256 tvl);

    /**
     * @notice Returns the claimable token amount as interest by the `stakeHolder`.
     * @param stakeHolder address of the stake holder.
     * @return claimableInterest The amount of interest gained by `stakeHolder`.
     */
    function claimableInterestGainedBy(
        address stakeHolder
    ) external view returns (uint256 claimableInterest);

    /// WRITE METHODS ///

    /**
     * @notice Allows a stake holder to stake tokens.
     * @dev Stake holder must first approve the `_amount` to stake before calling this function.
     * @param _amount The amount to be deposited.
     * @dev That the `amount` deposited should greater than 0.
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Allows a user to withdraw its initial deposit.
     * @param _amount The amount to withdraw.
     * @dev `_amount` must be higher than `0`.
     * @dev `_amount` must be lower or equal to the amount staked.
     * @dev Updating the stake holder details and claim rewards if rewards to claim.
     */
    function unstake(uint256 _amount) external;

    /**
     * @notice Claims pending tokens gained as interest.
     * @dev Transfers the gained tokens to the `msg.sender/caller`
     */
    function claimGainedInterest() external;

    /**
     * @notice Claims pending ETH reward and re lock the stake for another lock-in-period.
     * @dev Distribute ETH reward with no compound.
     */
    function claimETHAndReLock() external;

    /**
     * @notice Claims pending ETH reward and convert into `token` and then re-stake for another lock-in-period.
     * @dev Convert ETH reward to `token` and re invest.
     * @param _minReceive The min receive from dex.
     */
    function compoundETHAndReLock(uint256 _minReceive) external;

    /**
     * @notice Deposit ETH rewards into contract.
     * @dev Internally calls `_depositETHRewards`.
     */
    function depositETHRewards() external payable;

    /**
     * @notice Returns the realized ETH for the `_stakeHolder`
     * @param _stakeHolder The address of the stake holder.
     */
    function getRealizedETH(
        address _stakeHolder
    ) external view returns (uint256 realizedETH);

    /// EVENTS ///

    /**
     * @notice Emitted when `lockInPeriod` gets updated.
     * @param oldPeriod The previous lock in period.
     * @param newPeriod The new updated lock in period.
     */
    event LockInPeriodUpdated(uint256 indexed oldPeriod, uint256 newPeriod);

    /**
     * @notice Emitted when `fixedAPR` gets updated.
     * @param oldAPR The previous APR.
     * @param newAPR The new updated APR.
     */
    event APRUpdated(uint256 indexed oldAPR, uint256 newAPR);

    /**
     * @notice Emitted when `amount` tokens are deposited into pool contract.
     * @param stakeHolder The stake holder address who staked.
     * @param amount The amount stake holder staked.
     */
    event Deposited(address indexed stakeHolder, uint256 amount);

    /**
     * @notice Emitted when someone deposited ETH for reward distribution.
     * @param depositor The address of the depositor.
     * @param amount The amount of ETH deposited.
     */
    event DepositedETHRewards(address depositor, uint256 amount);

    /**
     * @notice Emitted when user withdraw deposited `amount`.
     * @param stakeHolder The stake holder address who withdrawn.
     * @param amount The amount stake holder withdrawn.
     */
    event Withdrawn(address indexed stakeHolder, uint256 amount);

    /**
     * @dev Emitted when `stakeHolder` claim their pending interest.
     * @param stakeHolder The stake holder address who claimed.
     * @param amount The amount of interest claimed.
     */
    event InterestClaimed(address indexed stakeHolder, uint256 amount);

    /**
     * @notice Emitted when `stakeHolder` claims ETH.
     * @param stakeHolder The stake holder address who claimed reward.
     * @param reward The amount of reward stakeHolder claimed.
     */
    event ETHRewardDistributed(address stakeHolder, uint256 reward);

    /// ERRORS ///

    error TypeAI__ZeroAddress(address caller);
    error TypeAI__ZeroAPR(address caller);

    /**
     * @notice Fired when a non stake holder trying to claims interest.
     * @param caller Address who is trying to claim.
     */
    error TypeAI__NotAStakeHolder(address caller);

    /**
     * @notice Fired when someone trying to deposit ETH but no stake available.
     * @param caller Address who is trying to deposit ETH.
     */
    error TypeAI_NoTVLAvailable(address caller);

    /**
     * @notice Fired when stake holder claims 0 interest.
     * @param stakeHolder Address who is trying to claim.
     */
    error TypeAI__NoInterestGained(address stakeHolder);

    /**
     * @notice Fired when stake holder trying to withdraw greater than his deposit.
     * @param stakeHolder Address who is trying to withdraw.
     */
    error TypeAI__InsufficientDepositAmount(address stakeHolder);

    /**
     * @notice Fired when owner trying to withdraw greater than residual balance.
     */
    error TypeAI__InsufficientResidualBalance();

    /**
     * @notice Fired when owner trying to withdraw greater than residual balance.
     */
    error TypeAI__ETHTransferFailed(address receiver, uint256 amount);

    /**
     * @notice Fired when owner trying to withdraw greater than residual balance.
     */
    error TypeAI__InvalidETHBalance(address receiver, uint256 amount);
    /**
     * @notice Fired when owner trying to withdraw reward while no reward available in the contract.
     * @param stakeHolder Address who is trying to claim.
     * @param required The required amount.
     */
    error TypeAI__InsufficientRewardPresent(
        address stakeHolder,
        uint256 required
    );

    /**
     * @notice Fired when stake holder trying to deposit 0 token.
     * @param stakeHolder Address who is trying to deposit.
     */
    error TypeAI__AmountMustBeGreaterThanZero(address stakeHolder);

    /**
     * @notice Fired when stake holder trying to withdraw tokens before
     * lock-in-period ends.
     * @param stakeHolder Address who is trying to withdraw.
     */
    error TypeAI__UnderLockInPeriod(address stakeHolder);
}
