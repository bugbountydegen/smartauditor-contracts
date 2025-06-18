// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*
.____                             ________
|    |   _____  ___.__. __________\_____  \
|    |   \__  \<   |  |/ __ \_  __ \_(__  <
|    |___ / __ \\___  \  ___/|  | \/       \
|_______ (____  / ____|\___  >__| /______  /
        \/    \/\/         \/            \/

https://layer3.xyz

Made with ♥ by Wonderland (https://defi.sucks)

*/

import {IDistributor} from 'interfaces/IDistributor.sol';
import {IStaking} from 'interfaces/IStaking.sol';
import {Ownable2StepUpgradeable} from 'openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol';

import {UUPSUpgradeable} from 'openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {PausableUpgradeable} from 'openzeppelin-upgradeable/utils/PausableUpgradeable.sol';
import {IERC20, SafeERC20} from 'openzeppelin/token/ERC20/utils/SafeERC20.sol';

import {Math} from 'openzeppelin/utils/math/Math.sol';
import {SafeCast} from 'openzeppelin/utils/math/SafeCast.sol';

contract Staking is IStaking, Ownable2StepUpgradeable, UUPSUpgradeable, PausableUpgradeable {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;
  using Math for uint256;

  /// @notice The lockup periods
  uint256 internal constant _12_MONTHS = 12 * 30 days;
  uint256 internal constant _18_MONTHS = 18 * 30 days;
  uint256 internal constant _24_MONTHS = 24 * 30 days;
  uint256 internal constant _36_MONTHS = 36 * 30 days;

  /// @notice The base value for calculations
  uint256 internal constant _BASE = 1e18;

  /// @inheritdoc IStaking
  IERC20 public token;

  /// @inheritdoc IStaking
  IDistributor public distributor;

  /// @inheritdoc IStaking
  uint256 public rewardsDuration;

  /// @inheritdoc IStaking
  uint256 public periodFinish;

  /// @inheritdoc IStaking
  uint256 public lastUpdateTime;

  /// @inheritdoc IStaking
  uint256 public rewardPerSecond;

  /// @inheritdoc IStaking
  uint256 public rewardPerShare;

  /// @inheritdoc IStaking
  uint256 public totalRewards;

  /// @inheritdoc IStaking
  uint256 public totalDeposits;

  /// @inheritdoc IStaking
  uint256 public totalWeights;

  /// @inheritdoc IStaking
  uint256 public withdrawalPeriod;

  /// @inheritdoc IStaking
  mapping(address _user => Staker _staker) public stakers;

  /// @inheritdoc IStaking
  mapping(address _user => mapping(uint256 _index => Deposit _deposit)) public deposits;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(IERC20 _token, IDistributor _distributor, address _owner) public initializer {
    token = _token;
    distributor = _distributor;
    rewardsDuration = 5 * 12 * 30 days;
    withdrawalPeriod = 7 days;

    __Ownable_init(_owner);
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __Pausable_init();

    _pause();
  }

  /// @inheritdoc IStaking
  function stake(uint256 _amount, uint256 _lockupPeriod) external {
    Deposit memory _deposit = _stake(_amount, _lockupPeriod, msg.sender);
    emit Staked(msg.sender, _deposit.index, _deposit.amount, _deposit.lockupPeriod, _deposit.unlockAt);

    // Transfer the tokens to the contract
    token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @inheritdoc IStaking
  function stake(uint256 _amount, uint256 _lockupPeriod, address _user) external {
    if (msg.sender != address(distributor)) revert OnlyDistributor();
    // The distributor will transfer the tokens after calling this function
    Deposit memory _deposit = _stake(_amount, _lockupPeriod, _user);
    emit Staked(_user, _deposit.index, _deposit.amount, _deposit.lockupPeriod, _deposit.unlockAt);
  }

  /// @inheritdoc IStaking
  function increaseStake(uint256 _index, uint256 _amount) external {
    _increaseStake(_index, _amount, msg.sender);
    emit StakeIncreased(msg.sender, _index, _amount);

    // Transfer the tokens to the contract
    token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @inheritdoc IStaking
  function stakeUnlocked(uint256 _index, uint256 _newLockupPeriod) external {
    Deposit memory _currentDeposit = deposits[msg.sender][_index];
    uint256 _currentAmount = _currentDeposit.amount;

    if (_currentAmount == 0) revert InvalidDepositIndex();
    if (_currentDeposit.unlockAt > block.timestamp) revert DepositLocked();
    if (_currentDeposit.withdrawAt > 0) revert WithdrawalAlreadyInitiated();
    if (_currentDeposit.lockupPeriod >= _newLockupPeriod) revert InvalidLockupPeriod();

    // Close the current stake
    _decreaseStake(_currentDeposit);

    // Delete the current staked deposit
    delete deposits[msg.sender][_index];
    totalDeposits -= _currentAmount;

    // Stake using the same amount but with the new lockup period
    Deposit memory _newDeposit = _stake(_currentAmount, _newLockupPeriod, msg.sender);

    emit StakedUnlocked(
      msg.sender, _newDeposit.index, _newDeposit.amount, _newDeposit.lockupPeriod, _newDeposit.unlockAt
    );
  }

  /// @inheritdoc IStaking
  function getReward() external {
    Staker storage _staker = _updateReward(msg.sender);
    uint256 _reward = _staker.pendingRewards;
    if (_reward > 0) {
      _staker.pendingRewards = 0;
      totalRewards -= _reward;
      token.safeTransfer(msg.sender, _reward);
      emit RewardPaid(msg.sender, _reward);
    }
  }

  /// @inheritdoc IStaking
  function getRewardAndStake(uint256 _lockupPeriod) external {
    Staker storage _staker = _updateReward(msg.sender);
    uint256 _reward = _staker.pendingRewards;
    if (_reward > 0) {
      _staker.pendingRewards = 0;
      Deposit memory _deposit = _stake(_reward, _lockupPeriod, msg.sender);
      totalRewards -= _reward;
      emit ClaimRewardAndStake(msg.sender, _deposit.index, _reward, _lockupPeriod);
    }
  }

  /// @inheritdoc IStaking
  function getRewardAndIncreaseStake(uint256 _index) external {
    Staker storage _staker = _updateReward(msg.sender);
    uint256 _reward = _staker.pendingRewards;
    if (_reward > 0) {
      _staker.pendingRewards = 0;
      _increaseStake(_index, _reward, msg.sender);
      totalRewards -= _reward;
      emit ClaimRewardAndIncreaseStake(msg.sender, _index, _reward);
    }
  }

  /// @inheritdoc IStaking
  function initiateWithdrawal(uint256 _index) external {
    // Get the Deposit struct
    Deposit storage _deposit = deposits[msg.sender][_index];

    if (_deposit.amount == 0) revert InvalidDepositIndex();
    if (_deposit.lockupPeriod > 0) revert DepositLocked();
    if (_deposit.withdrawAt > 0) revert WithdrawalAlreadyInitiated();

    _decreaseStake(_deposit);

    // Update the withdrawal timestamp
    _deposit.withdrawAt = (block.timestamp + withdrawalPeriod).toUint40();

    emit WithdrawalInitiated(msg.sender, _index, _deposit.withdrawAt);
  }

  /// @inheritdoc IStaking
  function cancelWithdrawal(uint256 _index) external {
    // Get the Deposit struct
    Deposit storage _deposit = deposits[msg.sender][_index];
    uint256 _amount = _deposit.amount;

    if (_deposit.amount == 0) revert InvalidDepositIndex();
    if (_deposit.withdrawAt == 0) revert WithdrawalNotInitiated();

    Staker storage _staker = _updateReward(msg.sender);

    // Because the deposit is unlocked, we're calculating the weight with a lockup period of 0
    uint256 _weight = _calculateWeight(0, _amount);

    // Update the total weights and user weight and reset the withdrawal timestamp
    totalWeights += _weight;
    _staker.weight += _weight.toUint128();
    _deposit.withdrawAt = 0;

    emit WithdrawalCancelled(msg.sender, _index);
  }

  /// @inheritdoc IStaking
  function withdraw(uint256 _index) external {
    // Get the Deposit struct
    Deposit memory _deposit = deposits[msg.sender][_index];

    if (_deposit.amount == 0) revert InvalidDepositIndex();

    if (_deposit.lockupPeriod > 0) {
      if (_deposit.unlockAt > block.timestamp) revert DepositLocked();
      _decreaseStake(_deposit);
    } else if (withdrawalPeriod == 0 && _deposit.withdrawAt == 0) {
      _decreaseStake(_deposit);
    } else {
      // Non-lockup deposits can be withdrawn only after a withdrawal period
      if (_deposit.withdrawAt > block.timestamp) revert DepositNotWithdrawable();
      if (_deposit.withdrawAt == 0) revert WithdrawalNotInitiated();
      // Not updating weights because the deposit was already removed from the total in `initiateWithdrawal`
    }

    // Update the total deposits
    totalDeposits -= _deposit.amount;

    // Delete the deposit
    delete deposits[msg.sender][_index];

    // Transfer the tokens to the user
    token.safeTransfer(msg.sender, _deposit.amount);
    emit Withdrawn(msg.sender, _index, _deposit.amount);
  }

  /// @inheritdoc IStaking
  function emergencyWithdraw(uint256 _amount) external onlyOwner {
    if (_amount == 0) revert ZeroAmount();

    // Withdraw either the requested amount or the remaining balance
    uint256 _remainingBalance = token.balanceOf(address(this));
    uint256 _withdrawalAmount = _amount > _remainingBalance ? _remainingBalance : _amount;

    token.safeTransfer(owner(), _withdrawalAmount);
    emit EmergencyWithdrawn(owner(), _withdrawalAmount);
  }

  /// @inheritdoc IStaking
  function setRewardAmount(uint256 _reward) external onlyOwner {
    uint256 _currentBalance = token.balanceOf(address(this));
    if (_reward > _currentBalance - totalDeposits - totalRewards) revert InsufficientBalance();

    _updateReward(address(0));

    if (block.timestamp >= periodFinish) {
      rewardPerSecond = _reward / rewardsDuration;
    } else {
      uint256 _remaining = periodFinish - block.timestamp;
      uint256 _leftover = _remaining * rewardPerSecond;
      rewardPerSecond = (_reward + _leftover) / rewardsDuration;
    }

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;
    totalRewards += _reward;
    emit RewardAdded(_reward);
  }

  /// @inheritdoc IStaking
  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    if (periodFinish > block.timestamp) revert PeriodNotFinished();

    uint256 _oldRewardsDuration = rewardsDuration;
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(_oldRewardsDuration, _rewardsDuration);
  }

  /// @inheritdoc IStaking
  function setWithdrawalPeriod(uint256 _withdrawalPeriod) external onlyOwner {
    uint256 _oldWithdrawalPeriod = withdrawalPeriod;

    withdrawalPeriod = _withdrawalPeriod;
    emit WithdrawalPeriodUpdated(_oldWithdrawalPeriod, _withdrawalPeriod);
  }

  /// @inheritdoc IStaking
  function pause() external onlyOwner {
    _pause();
  }

  /// @inheritdoc IStaking
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @inheritdoc IStaking
  function setDistributorAddress(IDistributor _distributor) external onlyOwner {
    IDistributor _oldDistributor = distributor;

    distributor = _distributor;
    emit DistributorUpdated(_oldDistributor, _distributor);
  }

  /// @inheritdoc IStaking
  function collectDust(IERC20 _token, uint256 _amount) external onlyOwner {
    if (_token == token || address(_token) == address(0)) revert InvalidToken();
    if (_amount == 0) revert ZeroAmount();

    address _owner = owner();

    _token.safeTransfer(_owner, _amount);

    emit DustCollected(_owner, _token, _amount);
  }

  /// @inheritdoc IStaking
  function calculateAPY(uint256 _amount, uint256 _lockupPeriod) external view returns (uint256 _apy) {
    uint256 _weight = _calculateWeight(_lockupPeriod, _amount);
    uint256 _rewardPerYear = rewardPerSecond * _12_MONTHS * _BASE * 100;

    _apy = Math.mulDiv(_weight, _rewardPerYear, (totalWeights + _weight) * _amount);
  }

  /// @inheritdoc IStaking
  function calculateAPY(address _user, uint256 _index) external view returns (uint256 _apy) {
    Deposit memory _deposit = deposits[_user][_index];
    uint256 _weight = _calculateWeight(_deposit.lockupPeriod, _deposit.amount);
    uint256 _rewardPerYear = rewardPerSecond * _12_MONTHS * _BASE * 100;

    _apy = Math.mulDiv(_weight, _rewardPerYear, _deposit.amount * totalWeights);
  }

  /// @inheritdoc IStaking
  function listDeposits(
    address _user,
    uint256 _startFrom,
    uint256 _batchSize
  ) external view returns (Deposit[] memory _list) {
    uint256 _totalDeposits = stakers[_user].depositCount;

    // Return an empty array if non-existent user or no deposits
    if (_startFrom > _totalDeposits) {
      return _list;
    }

    if (_batchSize > _totalDeposits - _startFrom) {
      _batchSize = _totalDeposits - _startFrom;
    }

    _list = new Deposit[](_batchSize);

    uint256 _index;
    while (_index < _batchSize) {
      _list[_index] = deposits[_user][_startFrom + _index];
      ++_index;
    }
  }

  /// @inheritdoc IStaking
  function pendingRewards(address _user) public view returns (uint256 _pendingRewards) {
    Staker storage _staker = stakers[_user];

    // Staker's pendingRewards already accounts for rewards calculated prior to the last snapshot
    // We take the difference between the current rate and the one pendingRewards was calculated at
    // And work out the amount of rewards accumulated after the snapshot
    uint256 _rateDifferenceSinceSnapshot = _calculatedRewardPerShare() - _staker.rewardPerShareSnapshot;
    uint256 _rewardsSinceSnapshot = _staker.weight * _rateDifferenceSinceSnapshot / _BASE;
    _pendingRewards = _staker.pendingRewards + _rewardsSinceSnapshot;
  }

  /**
   * @notice Stakes the provided amount of tokens and increases the total weight
   * @param _amount The amount of tokens
   * @param _lockupPeriod The lockup period
   * @param _user The address of the user
   */
  function _stake(uint256 _amount, uint256 _lockupPeriod, address _user) internal returns (Deposit memory _deposit) {
    if (_amount == 0) revert ZeroAmount();
    Staker storage _staker = _updateReward(_user);

    // Calculate the user weight, taking into account the lockup period multiplier
    uint256 _weight = _calculateWeight(_lockupPeriod, _amount);

    if (_weight == 0) revert ZeroWeight();

    // Update the total weights and user weight
    totalWeights += _weight;
    totalDeposits += _amount;
    _staker.weight += _weight.toUint128();

    // Get the last index and increment it
    uint256 _lastIndex = _staker.depositCount++;
    uint256 _unlockAt = block.timestamp + _lockupPeriod;

    _deposit = Deposit({
      amount: _amount.toUint128(),
      unlockAt: _unlockAt.toUint40(),
      lockupPeriod: _lockupPeriod.toUint32(),
      index: _lastIndex.toUint16(),
      withdrawAt: 0
    });

    // Create a new Deposit struct
    deposits[_user][_lastIndex] = _deposit;
  }

  /**
   * @notice Updates the reward rate and the staker's info
   * @param _user The address of the user
   * @return _staker The staker struct
   */
  function _updateReward(address _user) internal whenNotPaused returns (Staker storage _staker) {
    uint256 _rewardPerShare = _calculatedRewardPerShare();
    if (_rewardPerShare == 0 || _rewardPerShare > rewardPerShare) {
      rewardPerShare = _rewardPerShare;
      lastUpdateTime = _lastTimeRewardApplicable();
    }

    _staker = stakers[_user];
    if (_user != address(0)) {
      _staker.pendingRewards = pendingRewards(_user).toUint128();
      _staker.rewardPerShareSnapshot = rewardPerShare.toUint128();
    }
  }

  /**
   * @notice Adds the specified amount of tokens the specified deposit
   * @param _index The index of the deposit
   * @param _amount The amount of tokens
   * @param _user The address of the user
   * @dev Only unlocked deposits can be increased
   */
  function _increaseStake(uint256 _index, uint256 _amount, address _user) internal {
    Deposit storage _deposit = deposits[_user][_index];

    if (_deposit.amount == 0) revert InvalidDepositIndex();
    if (_deposit.lockupPeriod > 0) revert CannotIncreaseLockedStake();
    if (_deposit.withdrawAt > 0) revert WithdrawalAlreadyInitiated();

    // Because the deposit is unlocked, we're calculating the weight with a lockup period of 0
    uint256 _weight = _calculateWeight(0, _amount);

    // Update the total weights and user weight
    Staker storage _staker = _updateReward(_user);
    totalWeights += _weight;
    totalDeposits += _amount;
    _staker.weight += _weight.toUint128();
    _deposit.amount += _amount.toUint128();
  }

  /**
   * @notice Decreases the stake of the specified deposit
   * @param _deposit The deposit to decrease
   */
  function _decreaseStake(Deposit memory _deposit) internal {
    Staker storage _staker = _updateReward(msg.sender);

    // Calculate the user weight
    uint256 _weight = _calculateWeight(_deposit.lockupPeriod, _deposit.amount);

    // Avoid rounding issues where `weight(a) + weight(b) <= weight(a+b)` that may cause underflows
    _weight = _weight <= _staker.weight ? _weight : _staker.weight;

    // Update the total weights and user weight
    totalWeights -= _weight;
    _staker.weight -= _weight.toUint128();
  }

  /**
   * @notice Returns either the current time or the end of the rewards period, whichever is earlier
   * @return _lastTimeReward The timestamp of the last time rewards were applicable
   */
  function _lastTimeRewardApplicable() internal view returns (uint256 _lastTimeReward) {
    _lastTimeReward = block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  /**
   * @notice Calculates the reward per share
   * @return _rewardPerShare The reward per share
   */
  function _calculatedRewardPerShare() internal view returns (uint256 _rewardPerShare) {
    if (totalWeights == 0) {
      return rewardPerShare;
    }

    uint256 _timeSinceLastUpdate = _lastTimeRewardApplicable() - lastUpdateTime;

    _rewardPerShare = rewardPerShare + _timeSinceLastUpdate * rewardPerSecond * _BASE / totalWeights;
  }

  /**
   * @notice Applies the lockup period multiplier to get the deposit's weight
   * @param _lockupPeriod The lockup period
   * @param _amount The amount of tokens
   * @return _weight The weight of the deposit
   */
  function _calculateWeight(uint256 _lockupPeriod, uint256 _amount) internal pure returns (uint256 _weight) {
    if (_lockupPeriod == 0) {
      _weight = _amount * 250 / 1000;
    } else if (_lockupPeriod == _12_MONTHS) {
      _weight = _amount * 500 / 1000;
    } else if (_lockupPeriod == _18_MONTHS) {
      _weight = _amount * 625 / 1000;
    } else if (_lockupPeriod == _24_MONTHS) {
      _weight = _amount * 750 / 1000;
    } else if (_lockupPeriod == _36_MONTHS) {
      _weight = _amount;
    } else {
      revert InvalidLockupPeriod();
    }
  }

  /**
   * @notice Checks if the contract upgrade is authorized
   * @param _newImplementation The address of the new implementation
   * @dev Only owner should be allowed to perform upgrades
   */
  function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
