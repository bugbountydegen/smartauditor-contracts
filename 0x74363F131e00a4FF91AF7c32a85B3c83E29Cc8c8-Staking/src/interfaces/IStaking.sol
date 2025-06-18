// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IDistributor} from './IDistributor.sol';
import {IERC20} from 'openzeppelin/token/ERC20/utils/SafeERC20.sol';

interface IStaking {
  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Deposit struct
   * @param amount The amount of tokens deposited
   * @param unlockAt The timestamp when the tokens can be unlocked
   * @param lockupPeriod The period the tokens are locked for to get the bonus
   * @param index The index of the deposit
   * @param withdrawAt The timestamp when the tokens can be withdrawn (after withdrawal period is over)
   */
  struct Deposit {
    uint128 amount;
    uint40 unlockAt;
    uint32 lockupPeriod;
    uint16 index;
    uint40 withdrawAt;
  }

  /**
   * @notice Staker struct
   * @param weight The combined weight of the staker's deposits
   * @param depositCount The number of deposits the staker has
   * @param rewardPerShareSnapshot The amount of rewards per share as seen at the last update
   * @param pendingRewards The amount of rewards available to be claimed by the staker
   */
  struct Staker {
    uint128 weight;
    uint128 depositCount;
    uint128 rewardPerShareSnapshot;
    uint128 pendingRewards;
  }

  /*///////////////////////////////////////////////////////////////
                                EVENTS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the user stakes tokens
   * @param _user The user that staked the tokens
   * @param _index The index of the deposit
   * @param _amount The amount of tokens staked
   * @param _lockupPeriod The lockup period
   * @param _unlockAt The timestamp when the tokens can be withdrawn
   */
  event Staked(
    address indexed _user, uint256 indexed _index, uint256 _amount, uint256 _lockupPeriod, uint256 _unlockAt
  );

  /**
   * @notice Emitted when the user stakes again an unlocked deposit
   * @param _user The user that staked the tokens
   * @param _index The index of the deposit
   * @param _amount The amount of tokens staked
   * @param _lockupPeriod The lockup period
   * @param _unlockAt The timestamp when the tokens can be withdrawn
   */
  event StakedUnlocked(
    address indexed _user, uint256 indexed _index, uint256 _amount, uint256 _lockupPeriod, uint256 _unlockAt
  );

  /**
   * @notice Emitted when the user adds tokens to an existing stake
   * @param _user The user that staked the tokens
   * @param _index The index of the deposit
   * @param _amount The amount of tokens added
   */
  event StakeIncreased(address indexed _user, uint256 indexed _index, uint256 _amount);

  /**
   * @notice Emitted when the user claims pending rewards and creates a new deposit
   * @param _user The user that staked the rewards
   * @param _index The index of the created stake
   * @param _amount The amount of tokens staked
   * @param _lockupPeriod The lockup period
   */
  event ClaimRewardAndStake(address indexed _user, uint256 indexed _index, uint256 _amount, uint256 _lockupPeriod);

  /**
   * @notice Emitted when the user claims pending rewards and adds the tokens to an existing stake
   * @param _user The user that staked the tokens
   * @param _index The index of the deposit
   * @param _amount The amount of tokens added
   */
  event ClaimRewardAndIncreaseStake(address indexed _user, uint256 indexed _index, uint256 _amount);

  /**
   * @notice Emitted when the user initiates a withdrawal
   * @param _user The user that initiated the withdrawal
   * @param _index The index of the deposit
   * @param _withdrawAt The end of the withdrawal period
   */
  event WithdrawalInitiated(address indexed _user, uint256 indexed _index, uint256 _withdrawAt);

  /**
   * @notice Emitted when the user cancels the withdrawal
   * @param _user The user that cancelled the withdrawal
   * @param _index The index of the deposit
   */
  event WithdrawalCancelled(address indexed _user, uint256 indexed _index);

  /**
   * @notice Emitted when the user withdraws tokens
   * @param _user The user that withdrew the tokens
   * @param _index The index of the deposit
   * @param _amount The amount of tokens withdrawn
   */
  event Withdrawn(address indexed _user, uint256 indexed _index, uint256 _amount);

  /**
   * @notice Emitted when the user claims their rewards
   * @param _user The user that claimed the rewards
   * @param _amount The amount of rewards claimed
   */
  event RewardPaid(address indexed _user, uint256 _amount);

  /**
   * @notice Emitted when the reward amount is added
   * @param _reward The new reward amount
   */
  event RewardAdded(uint256 _reward);

  /**
   * @notice Emitted when the rewards duration is updated
   * @param _oldRewardsDuration The previous rewards duration
   * @param _rewardsDuration The new rewards duration
   */
  event RewardsDurationUpdated(uint256 _oldRewardsDuration, uint256 _rewardsDuration);

  /**
   * @notice Emitted when the dust tokens are collected
   * @param _owner The owner that collected the dust tokens
   * @param _token The token address
   * @param _amount The amount of tokens collected
   */
  event DustCollected(address indexed _owner, IERC20 _token, uint256 _amount);

  /**
   * @notice Emitted when the staked deposits and the rewards are retracted by the owner
   * @param _owner The owner that withdrew the tokens
   * @param _amount The amount of tokens retracted
   */
  event EmergencyWithdrawn(address indexed _owner, uint256 _amount);

  /**
   * @notice Emitted when the withdrawal period is updated
   * @param _oldWithdrawalPeriod The previous withdrawal period
   * @param _withdrawalPeriod The new withdrawal period
   */
  event WithdrawalPeriodUpdated(uint256 _oldWithdrawalPeriod, uint256 _withdrawalPeriod);

  /**
   * @notice Emitted when the distributor address is updated
   * @param _oldDistributor The previous distributor
   * @param _distributor The new distributor
   */
  event DistributorUpdated(IDistributor _oldDistributor, IDistributor _distributor);

  /*///////////////////////////////////////////////////////////////
                                ERRORS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the provided amount is zero
   */
  error ZeroAmount();

  /**
   * @notice Throws if the provided weight is zero
   */
  error ZeroWeight();

  /**
   * @notice Throws if the deposit with the given index does not exist
   */
  error InvalidDepositIndex();

  /**
   * @notice Throws if trying to withdraw a locked deposit
   */
  error DepositLocked();

  /**
   * @notice Throws if the lockup period is invalid
   */
  error InvalidLockupPeriod();

  /**
   * @notice Throws if the staking contract has insufficient balance to pay the rewards at the given rate
   */
  error InsufficientBalance();

  /**
   * @notice Throws if the period is not finished
   */
  error PeriodNotFinished();

  /**
   * @notice Throws if the token is invalid
   */
  error InvalidToken();

  /**
   * @notice Throws if the caller is not the distributor
   */
  error OnlyDistributor();

  /**
   * @notice Throws if the caller is trying to add tokens to a locked deposit
   */
  error CannotIncreaseLockedStake();

  /**
   * @notice Throws if the withdrawal is not initiated while trying to withdraw
   */
  error WithdrawalNotInitiated();

  /**
   * @notice Throws if the caller is trying to initiate a withdrawal of a deposit that's already in the withdrawal process
   */
  error WithdrawalAlreadyInitiated();

  /**
   * @notice Throws if the withdrawal period is not over while trying to withdraw
   */
  error DepositNotWithdrawable();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the token contract
   * @return _token The token contract
   */
  function token() external view returns (IERC20 _token);

  /**
   * @notice The address of the distributor contract
   * @return _distributor The distributor contract
   */
  function distributor() external view returns (IDistributor _distributor);

  /**
   * @notice The time period in seconds over which rewards are distributed
   * @return _rewardsDuration The rewards duration
   */
  function rewardsDuration() external view returns (uint256 _rewardsDuration);

  /**
   * @notice Returns the timestamp of the last block at which the rewards will be distributed
   * @return _periodFinish The end of the rewards period
   */
  function periodFinish() external view returns (uint256 _periodFinish);

  /**
   * @notice The amount of rewards given to the stakers every second
   * @return _rewardPerSecond The amount of reward per second
   */
  function rewardPerSecond() external view returns (uint256 _rewardPerSecond);

  /**
   * @notice The time the reward per second was updated
   * @return _lastUpdateTime The last time the reward per second was updated
   */
  function lastUpdateTime() external view returns (uint256 _lastUpdateTime);

  /**
   * @notice The total weight of the deposits in the contract
   * @return _totalWeights The total weight of the deposits
   */
  function totalWeights() external view returns (uint256 _totalWeights);

  /**
   * @notice The total amount of tokens staked in the contract
   * @return _totalDeposits The amount of tokens staked in the contract
   */
  function totalDeposits() external view returns (uint256 _totalDeposits);

  /**
   * @notice The amount of tokens intended to be distributed as rewards
   * @return _totalRewards The total reward amount
   */
  function totalRewards() external view returns (uint256 _totalRewards);

  /**
   * @notice The reward generated per staker's share of the pool
   * @return _rewardPerShare The reward per share
   */
  function rewardPerShare() external view returns (uint256 _rewardPerShare);

  /**
   * @notice The time period in seconds after which the staker can withdraw their tokens
   * @dev This is only needed for non-lockup deposits
   * @return _withdrawalPeriod The withdrawal period
   */
  function withdrawalPeriod() external view returns (uint256 _withdrawalPeriod);

  /**
   * @notice Provides information about a given staker
   * @param _user The staker's address
   * @return _weight The total weight of the staker's deposits
   * @return _depositCount The number of deposits the staker has
   * @return _rewardPerShareSnapshot The amount of rewards per share as seen at the last update
   * @return _pendingRewards The amount of rewards pending to be claimed by the staker
   */
  function stakers(address _user)
    external
    view
    returns (uint128 _weight, uint128 _depositCount, uint128 _rewardPerShareSnapshot, uint128 _pendingRewards);

  /**
   * @notice Returns a user's deposit with the given index
   * @param _user The address of the user
   * @param _depositIndex The index of the deposit
   * @return _amount The amount of tokens deposited
   * @return _unlockAt The timestamp when the tokens can be withdrawn
   * @return _lockupPeriod The period the tokens are locked to get the bonus
   * @return _index The index of the deposit
   */
  function deposits(
    address _user,
    uint256 _depositIndex
  ) external view returns (uint128 _amount, uint40 _unlockAt, uint32 _lockupPeriod, uint16 _index, uint40 _withdrawAt);

  /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice The list of deposits of the user
   * @param _user The address of the user
   * @param _startFrom The index to start from
   * @param _batchSize The size of the batch
   * @return _list The list of deposits
   */
  function listDeposits(
    address _user,
    uint256 _startFrom,
    uint256 _batchSize
  ) external view returns (Deposit[] memory _list);

  /**
   * @notice Calculates APY based on the given amount and the lockup period
   * @param _amount The amount of tokens to stake
   * @param _lockupPeriod The lockup period
   * @return _apy The APY the staker would get
   */
  function calculateAPY(uint256 _amount, uint256 _lockupPeriod) external view returns (uint256 _apy);

  /**
   * @notice Returns the APY of an existing deposit
   * @param _user The staker address
   * @param _index The index of the deposit
   * @return _apy The APY the deposit is generating
   */
  function calculateAPY(address _user, uint256 _index) external view returns (uint256 _apy);

  /**
   * @notice The amount of pending rewards the staker has
   * @param _user The address of the user
   * @return _pendingRewards The amount of the rewards ready to be claimed
   */
  function pendingRewards(address _user) external view returns (uint256 _pendingRewards);

  /**
   * @notice The stake function
   * @param _amount The amount of tokens
   * @param _lockupPeriod The lockup period, must be either 0 or one of the allowed lockup periods
   */
  function stake(uint256 _amount, uint256 _lockupPeriod) external;

  /**
   * @notice The stake function for the distributor, allowing to stake on behalf of another address
   * @param _amount The amount of tokens
   * @param _lockupPeriod The lockup period, must be either 0 or one of the allowed lockup periods
   * @param _user The address of the user to stake for
   */
  function stake(uint256 _amount, uint256 _lockupPeriod, address _user) external;

  /**
   * @notice Add the provided amount of tokens to an existing stake
   * @param _amount The amount of tokens to add
   * @param _index The index of the deposit to increase
   */
  function increaseStake(uint256 _index, uint256 _amount) external;

  /**
   * @notice Stakes the unlocked deposit with a higher lockup period
   * @param _index The index of the deposit
   * @param _newLockupPeriod The new lockup period
   */
  function stakeUnlocked(uint256 _index, uint256 _newLockupPeriod) external;

  /**
   * @notice Claims pending rewards and adds them to an existing stake
   * @param _index The index of the deposit to increase
   */
  function getRewardAndIncreaseStake(uint256 _index) external;

  /**
   * @notice Initiates a withdrawal of the deposit
   * @dev The tokens will be locked for the withdrawal period
   * @dev Only needed for non-lockup deposits
   * @param _index The index of the deposit to withdraw
   */
  function initiateWithdrawal(uint256 _index) external;

  /**
   * @notice Cancels the withdrawal of the deposit
   * @param _index The index of the deposit to cancel the withdrawal
   */
  function cancelWithdrawal(uint256 _index) external;

  /**
   * @notice The withdraw function
   * @param _index The index of the deposit to withdraw
   */
  function withdraw(uint256 _index) external;

  /**
   * @notice Transfers pending rewards to the caller
   */
  function getReward() external;

  /**
   * @notice Claims the pending rewards and creates an unlocked deposit from them
   * @param _lockupPeriod The lockup period, must be either 0 or one of the allowed lockup periods
   */
  function getRewardAndStake(uint256 _lockupPeriod) external;

  /**
   * @notice Updates the total amount of rewards for the stakers
   * @param _reward The new reward amount
   */
  function setRewardAmount(uint256 _reward) external;

  /**
   * @notice Updates the rewards duration
   * @param _rewardsDuration The new rewards duration
   */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
   * @notice Updates the distributor address
   * @param _distributor The new distributor
   */
  function setDistributorAddress(IDistributor _distributor) external;

  /**
   * @notice Sends any dust tokens to the owner
   * @param _token The token address
   * @param _amount The amount of tokens to withdraw
   */
  function collectDust(IERC20 _token, uint256 _amount) external;

  /**
   * @notice An emergency function which sends the specified number of tokens to the owner
   * @param _amount The amount of tokens to withdraw
   */
  function emergencyWithdraw(uint256 _amount) external;

  /**
   * @notice Updates the withdrawal period
   * @param _withdrawalPeriod The new withdrawal period
   */
  function setWithdrawalPeriod(uint256 _withdrawalPeriod) external;

  /**
   * @notice Pauses the staking and withdrawals
   */
  function pause() external;

  /**
   * @notice Unpauses the staking and withdrawals
   */
  function unpause() external;
}
