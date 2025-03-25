// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IChainZoomVault.sol";

contract ChainZoomStaking is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IChainZoomVault public vault;
    address public zoomToken;

    uint256 public BRONZE_DURATION;
    uint256 public SILVER_DURATION;
    uint256 public GOLD_DURATION;
    uint256 public DIAMOND_DURATION;

    uint256 public BRONZE_F1_PERCENT;
    uint256 public BRONZE_F2_PERCENT;
    uint256 public SILVER_F1_PERCENT;
    uint256 public SILVER_F2_PERCENT;
    uint256 public GOLD_F1_PERCENT;
    uint256 public GOLD_F2_PERCENT;
    uint256 public DIAMOND_F1_PERCENT;
    uint256 public DIAMOND_F2_PERCENT;

    uint256 public EARLY_BIRD_F3_PERCENT;
    uint256 public EARLY_BIRD_DURATION;

    uint256 public ROUND_DURATION;
    uint256 public MAX_STAKES_PER_USER;
    uint256 public CLAIM_PERIOD;
    uint256 public AUTO_COMPOUND_THRESHOLD;

    struct UserStake {
        uint256 amount;
        uint256 startTime;
        uint256 stakeRound;
        bool earlyBird;
        bool claimed;
    }

    mapping(address => UserStake[]) public userStakes;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isEarlyBird;
    mapping(uint256 => bool) public roundClaimable;
    mapping(uint256 => address[]) public roundUserStakes;

    uint256 public launchTime;
    uint256 public currentRound;
    uint256 public lastRoundEndTime;
    uint256 public totalStaked;

    uint256 public totalRevenue;

    mapping(uint256 => uint256) public cumulativeF1Revenue;
    mapping(uint256 => uint256) public cumulativeF2Revenue;
    mapping(uint256 => uint256) public cumulativeF3Revenue;

    mapping(uint256 => uint256) public revenuePool; // P1: Revenue Sharing Pool
    mapping(uint256 => uint256) public rewardsPool; // P2: Rewards Pool
    mapping(uint256 => uint256) public remainingPool; // P3: Remaining Pool

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 startTime,
        uint256 round
    );

    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event DistributeRewards(
        uint256 indexed round,
        uint256 f1Revenue,
        uint256 f2Revenue,
        uint256 f3Revenue
    );

    function initialize(address _zoomToken, address _vault) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        BRONZE_DURATION = 2 weeks;
        SILVER_DURATION = 4 weeks;
        GOLD_DURATION = 8 weeks;
        DIAMOND_DURATION = 12 weeks;

        BRONZE_F1_PERCENT = 60;
        BRONZE_F2_PERCENT = 60;
        SILVER_F1_PERCENT = 75;
        SILVER_F2_PERCENT = 75;
        GOLD_F1_PERCENT = 85;
        GOLD_F2_PERCENT = 85;
        DIAMOND_F1_PERCENT = 100;
        DIAMOND_F2_PERCENT = 100;

        EARLY_BIRD_F3_PERCENT = 100;
        EARLY_BIRD_DURATION = 2 days;

        ROUND_DURATION = 30 days;
        MAX_STAKES_PER_USER = 50;
        CLAIM_PERIOD = 3 days;
        AUTO_COMPOUND_THRESHOLD = 0.5 ether;

        zoomToken = _zoomToken;
        vault = IChainZoomVault(_vault);

        // launchTime = block.timestamp;
        currentRound = 1;
    }

    function stake(uint256 _amount) public nonReentrant whenNotPaused {
        require(launchTime != 0, "Staking not started");
        require(_amount > 0, "Invalid stake amount");
        require(
            userStakes[_msgSender()].length < MAX_STAKES_PER_USER,
            "Maximum stakes reached"
        );

        require(
            block.timestamp <= launchTime + (currentRound * ROUND_DURATION),
            "Staking period ended"
        );

        vault.deposit(_amount, _msgSender(), zoomToken);
        totalStaked += _amount;

        uint256 startTime = block.timestamp;
        bool earlyBird = isEarlyBird[_msgSender()] || startTime <= launchTime + EARLY_BIRD_DURATION;

        userStakes[_msgSender()].push(
            UserStake(_amount, startTime, currentRound, earlyBird, false)
        );

        if (!hasStaked[_msgSender()]) {
            hasStaked[_msgSender()] = true;
            if (earlyBird) {
                isEarlyBird[_msgSender()] = true;
            }

            roundUserStakes[currentRound].push(_msgSender());
        }

        emit Staked(_msgSender(), _amount, startTime, currentRound);
    }

    function unstakeAll() public nonReentrant whenNotPaused {
        UserStake[] storage stakes = userStakes[_msgSender()];
        uint256 totalAmount = 0;
        uint256 totalReward = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].amount > 0) {
                // Claim rewards first
                if (!stakes[i].claimed && roundClaimable[stakes[i].stakeRound]) {
                    uint256 stakeReward = getStakeReward(stakes[i]);
                    if (stakeReward > 0) {
                        totalReward += stakeReward;
                        rewardsPool[stakes[i].stakeRound] += stakeReward;
                        remainingPool[stakes[i].stakeRound] -= stakeReward;
                        stakes[i].claimed = true;
                    }
                }
                // Unstake tokens
                totalAmount += stakes[i].amount;
                stakes[i].amount = 0;
            }
        }

        require(totalAmount > 0, "No stakes to unstake");

        vault.withdraw(totalAmount, _msgSender(), zoomToken);
        totalStaked -= totalAmount;

        if (totalReward > 0) {
            vault.withdraw(totalReward, _msgSender(), address(0));
            emit RewardClaimed(_msgSender(), totalReward);
        }

        emit Unstaked(_msgSender(), totalAmount);
    }

    function unstake(uint256 _positionIndex) public nonReentrant whenNotPaused {
        UserStake storage _stake = userStakes[_msgSender()][_positionIndex];
        require(_stake.amount > 0, "No tokens staked in this position");

        // Claim rewards first
        if (!_stake.claimed && roundClaimable[_stake.stakeRound]) {
            uint256 stakeReward = getStakeReward(_stake);
            if (stakeReward > 0) {
                vault.withdraw(stakeReward, _msgSender(), address(0));
                rewardsPool[_stake.stakeRound] += stakeReward;
                remainingPool[_stake.stakeRound] -= stakeReward;
                _stake.claimed = true;
                emit RewardClaimed(_msgSender(), stakeReward);
            }
        }

        // Unstake tokens
        uint256 stakedAmount = _stake.amount;
        vault.withdraw(stakedAmount, _msgSender(), zoomToken);
        totalStaked -= stakedAmount;
        _stake.amount = 0;

        emit Unstaked(_msgSender(), stakedAmount);
    }

    function unstakePartial(
        uint256 _positionIndex,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        UserStake storage _stake = userStakes[_msgSender()][_positionIndex];
        require(!_stake.claimed, "Position already unstaked");
        require(_amount <= _stake.amount, "Insufficient staked amount");

        _stake.amount -= _amount;
        totalStaked -= _amount;
        vault.withdraw(_amount, _msgSender(), zoomToken);

        emit Unstaked(_msgSender(), _amount);
    }

    function withdrawAll() public nonReentrant whenNotPaused {
        UserStake[] storage stakes = userStakes[_msgSender()];
        uint256 totalStakedAmount = 0;
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            if (!stakes[i].claimed && roundClaimable[stakes[i].stakeRound]) {
                totalStakedAmount += stakes[i].amount;
                uint256 stakeReward = getStakeReward(stakes[i]);
                totalRewardAmount += stakeReward;
                stakes[i].amount = 0;
                stakes[i].claimed = true;
                rewardsPool[stakes[i].stakeRound] += stakeReward;
                remainingPool[stakes[i].stakeRound] -= stakeReward;
            }
        }

        require(totalStakedAmount > 0, "No stakes to unstake");

        vault.withdraw(totalStakedAmount, _msgSender(), zoomToken);
        totalStaked -= totalStakedAmount;

        if (totalRewardAmount > 0) {
            vault.withdraw(totalRewardAmount, _msgSender(), address(0));
        }

        emit RewardClaimed(_msgSender(), totalRewardAmount);
        emit Unstaked(_msgSender(), totalStakedAmount);
    }

    function withdraw(
        uint256 _positionIndex
    ) public nonReentrant whenNotPaused {
        UserStake storage _stake = userStakes[_msgSender()][_positionIndex];
        require(_stake.amount > 0, "No tokens staked in this position");
        require(roundClaimable[_stake.stakeRound], "Not claimable yet");

        uint256 stakedAmount = _stake.amount;
        uint256 stakeReward = getStakeReward(_stake);

        vault.withdraw(stakedAmount, _msgSender(), zoomToken);
        totalStaked -= stakedAmount;

        if (stakeReward > 0) {
            vault.withdraw(stakeReward, _msgSender(), address(0));
            rewardsPool[_stake.stakeRound] += stakeReward;
            remainingPool[_stake.stakeRound] -= stakeReward;
        }

        _stake.amount = 0;
        _stake.claimed = true;

        emit RewardClaimed(_msgSender(), stakeReward);
        emit Unstaked(_msgSender(), stakedAmount);
    }

    function claimRewardAll() external {
        UserStake[] storage stakes = userStakes[_msgSender()];
        uint256 totalReward = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            UserStake storage _stake = stakes[i];
            if (!_stake.claimed && roundClaimable[_stake.stakeRound]) {
                uint256 stakeReward = getStakeReward(_stake);
                totalReward += stakeReward;
                _stake.claimed = true;
                rewardsPool[_stake.stakeRound] += stakeReward;
                remainingPool[_stake.stakeRound] -= stakeReward;
            }
        }

        require(totalReward > 0, "No rewards to claim");

        vault.withdraw(totalReward, _msgSender(), address(0));

        emit RewardClaimed(_msgSender(), totalReward);
    }

    function claimReward(uint256 _positionIndex) external {
        UserStake storage _stake = userStakes[_msgSender()][_positionIndex];
        require(roundClaimable[_stake.stakeRound], "Not claimable yet");
        require(!_stake.claimed, "Reward already claimed for this position");

        uint256 stakeReward = getStakeReward(_stake);
        require(stakeReward > 0, "No rewards to claim for this position");

        vault.withdraw(stakeReward, _msgSender(), address(0));
        rewardsPool[_stake.stakeRound] += stakeReward;
        remainingPool[_stake.stakeRound] -= stakeReward;

        _stake.claimed = true;

        emit RewardClaimed(_msgSender(), stakeReward);
    }

    function getClaimableAll(address _user) public view returns (uint256) {
        UserStake[] storage stakes = userStakes[_user];
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            UserStake storage _stake = stakes[i];
            if (!_stake.claimed && roundClaimable[_stake.stakeRound]) {
                uint256 stakeReward = getStakeReward(_stake);
                totalReward += stakeReward;
            }
        }
        return totalReward;
    }

    function getClaimable(
        address _user,
        uint256 _positionIndex
    ) public view returns (uint256) {
        UserStake storage _stake = userStakes[_user][_positionIndex];
        if (_stake.claimed) {
            return 0;
        }

        if (!roundClaimable[_stake.stakeRound]) {
            return 0;
        }

        uint256 stakeReward = getStakeReward(_stake);
        return stakeReward;
    }

    function getUserHighestTier(
        address _account
    ) public view returns (uint256) {
        uint256 highestTier = 0;
        for (uint256 i = 0; i < userStakes[_account].length; i++) {
            UserStake memory userStake = userStakes[_account][i];
            if (!userStake.claimed) {
                uint256 stakeTier = calculateStakeTier(userStake.startTime);
                if (stakeTier > highestTier) {
                    highestTier = stakeTier;
                }
            }
        }
        return highestTier;
    }

    function getUserTier(
        address _account,
        uint256 _positionIndex
    ) public view returns (uint256) {
        UserStake memory userStake = userStakes[_account][_positionIndex];
        if (!userStake.claimed) {
            return calculateStakeTier(userStake.startTime);
        }
        return 0; // No tier
    }

    function getPositionsByUser(
        address _account
    ) public view returns (UserStake[] memory) {
        UserStake[] memory result = new UserStake[](
            userStakes[_account].length
        );

        for (uint256 i = 0; i < userStakes[_account].length; i++) {
            result[i] = userStakes[_account][i];
        }

        return result;
    }

    function distributeRewards(
        uint256 _f1Revenue,
        uint256 _f2Revenue,
        uint256 _f3Revenue
    ) external payable onlyOwner {
        uint256 _totalRevenue = _f1Revenue + _f2Revenue + _f3Revenue;
        require(msg.value == _totalRevenue, "Incorrect revenue amount");
        vault.depositETH{value: msg.value}();

        cumulativeF1Revenue[currentRound] += _f1Revenue;
        cumulativeF2Revenue[currentRound] += _f2Revenue;
        cumulativeF3Revenue[currentRound] += _f3Revenue;

        totalRevenue += _totalRevenue;
        revenuePool[currentRound] += _totalRevenue; // F1 + F2 + F3
        remainingPool[currentRound] = revenuePool[currentRound];
        roundClaimable[currentRound] = true; // Set current round as claimable
        roundTotalStaked[currentRound] = totalStaked;

        emit DistributeRewards(currentRound, _f1Revenue, _f2Revenue, _f3Revenue);
    }

    function startNextRound() external onlyOwner {
        require(
            block.timestamp >= launchTime + (currentRound * ROUND_DURATION),
            "Round not ended"
        );

        // Transfer the remaining pool balance to the next round's revenue pool
        if (revenuePool[currentRound] > 0) {
            cumulativeF1Revenue[currentRound + 1] = remainingPool[currentRound] * cumulativeF1Revenue[currentRound] / revenuePool[currentRound];
            cumulativeF2Revenue[currentRound + 1] = remainingPool[currentRound] * cumulativeF2Revenue[currentRound] / revenuePool[currentRound];
            cumulativeF3Revenue[currentRound + 1] = remainingPool[currentRound] * cumulativeF3Revenue[currentRound] / revenuePool[currentRound];
        }

        revenuePool[currentRound + 1] = remainingPool[currentRound];

        // Initialize the pools for the next round
        rewardsPool[currentRound + 1] = 0;
        remainingPool[currentRound + 1] = 0;

        lastRoundEndTime = block.timestamp;

        // Update the stakeRound for all unstaked positions
        address[] storage _users = roundUserStakes[currentRound];
        for (uint256 i = 0; i < _users.length; i++) {
            UserStake[] storage stakes = userStakes[_users[i]];
            for (uint256 j = 0; j < stakes.length; j++) {
                if (stakes[j].amount > 0) {
                    stakes[j].stakeRound = currentRound + 1;
                }
            }
        }

        // Increment the current round
        currentRound++;
    }

    function getUnclaimedRewards(
        uint256 round
    ) external view returns (uint256) {
        uint256 unclaimedRewards = 0;

        address[] storage _users = roundUserStakes[round];
        for (uint256 i = 0; i < _users.length; i++) {
            UserStake[] storage stakes = userStakes[_users[i]];
            for (uint256 j = 0; j < stakes.length; j++) {
                if (!stakes[j].claimed && stakes[j].stakeRound == round) {
                    uint256 stakeReward = getStakeReward(stakes[j]);
                    unclaimedRewards += stakeReward;
                }
            }
        }

        return unclaimedRewards;
    }

    function autoCompound() external onlyOwner {
        require(
            block.timestamp > lastRoundEndTime + CLAIM_PERIOD,
            "Claim period not ended"
        );

        uint256 unclaimedRewards = 0;
        uint256 totalUnclaimedStakes = 0;

        address[] storage _users = roundUserStakes[currentRound];
        for (uint256 i = 0; i < _users.length; i++) {
            UserStake[] storage stakes = userStakes[_users[i]];
            for (uint256 j = 0; j < stakes.length; j++) {
                if (
                    !stakes[j].claimed && stakes[j].stakeRound == currentRound
                ) {
                    uint256 stakeReward = getStakeReward(stakes[j]);
                    unclaimedRewards += stakeReward;
                    totalUnclaimedStakes += stakes[j].amount;
                }
            }
        }

        // Check if the total unclaimed rewards exceed the auto-compound threshold
        if (unclaimedRewards > AUTO_COMPOUND_THRESHOLD) {
            // Swap unclaimed ETH rewards for $ZOOM tokens
            uint256 zoomTokensReceived = swapETHForTokens(unclaimedRewards);

            // Distribute the compounded tokens proportionally to unclaimed stakes
            if (totalUnclaimedStakes > 0) {
                for (uint256 i = 0; i < _users.length; i++) {
                    UserStake[] storage stakes = userStakes[_users[i]];
                    for (uint256 j = 0; j < stakes.length; j++) {
                        if (
                            !stakes[j].claimed &&
                            stakes[j].stakeRound == currentRound
                        ) {
                            uint256 compoundedAmount = (zoomTokensReceived *
                                stakes[j].amount) / totalUnclaimedStakes;
                            stakes[j].amount += compoundedAmount;
                        }
                    }
                }
            }

            // Update the total staked amount
            totalStaked += zoomTokensReceived;

            // Update the remaining pool balance
            remainingPool[currentRound] -= unclaimedRewards;
        }
    }

    function getStakeRewardAtPosition(
        address _account,
        uint256 _positionIndex
    ) public view returns (uint256) {
        UserStake memory _stake = userStakes[_account][_positionIndex];
        if (_stake.claimed) {
            return 0;
        }
        uint256 stakeDuration = block.timestamp - _stake.startTime;
        uint256 stakeReward = _calculateReward(
            stakeDuration,
            _stake.stakeRound,
            _stake.earlyBird,
            _stake.amount
        );
        return stakeReward;
    }

    function getStakeReward(
        UserStake memory _stake
    ) private view returns (uint256) {
        uint256 stakeDuration = block.timestamp - _stake.startTime;
        uint256 stakeReward = _calculateReward(
            stakeDuration,
            _stake.stakeRound,
            _stake.earlyBird,
            _stake.amount
        );
        return stakeReward;
    }

    function estimateRewards(
        uint256 _amount,
        uint256 _duration,
        uint256 _round,
        bool _earlyBird
    ) external view returns (uint256) {
        uint256 estimatedReward = _calculateReward(
            _duration,
            _round,
            _earlyBird,
            _amount
        );
        return estimatedReward;
    }

    function _calculateReward(
        uint256 _duration,
        uint256 _round,
        bool _earlyBird,
        uint256 _amount
    ) private view returns (uint256) {
        if (roundTotalStaked[_round] == 0) {
            return 0;
        }

        uint256 f1Percent = 0;
        uint256 f2Percent = 0;

        if (_duration >= DIAMOND_DURATION) {
            f1Percent = DIAMOND_F1_PERCENT;
            f2Percent = DIAMOND_F2_PERCENT;
        } else if (_duration >= GOLD_DURATION) {
            f1Percent = GOLD_F1_PERCENT;
            f2Percent = GOLD_F2_PERCENT;
        } else if (_duration >= SILVER_DURATION) {
            f1Percent = SILVER_F1_PERCENT;
            f2Percent = SILVER_F2_PERCENT;
        } else if (_duration >= BRONZE_DURATION) {
            f1Percent = BRONZE_F1_PERCENT;
            f2Percent = BRONZE_F2_PERCENT;
        }

        uint256 f1Reward = (cumulativeF1Revenue[_round] * f1Percent) / 100;
        uint256 f2Reward = (cumulativeF2Revenue[_round] * f2Percent) / 100;
        uint256 f3Reward = 0;

        if (_earlyBird) {
            f3Reward = (cumulativeF3Revenue[_round] * EARLY_BIRD_F3_PERCENT) / 100;
        }

        uint256 reward = ((f1Reward + f2Reward + f3Reward) * _amount) /
            roundTotalStaked[_round];
        return reward;
    }

    function calculateStakeTier(
        uint256 _startTime
    ) internal view returns (uint256) {
        uint256 stakeDuration = block.timestamp - _startTime;
        if (stakeDuration >= DIAMOND_DURATION) {
            return 4; // Diamond tier
        } else if (stakeDuration >= GOLD_DURATION) {
            return 3; // Gold tier
        } else if (stakeDuration >= SILVER_DURATION) {
            return 2; // Silver tier
        } else if (stakeDuration >= BRONZE_DURATION) {
            return 1; // Bronze tier
        }
        return 0; // No tier
    }

    function swapETHForTokens(uint256 ethAmount) private returns (uint256) {
        require(ethAmount > 0, "Invalid ETH value");

        uint256 deadline = block.timestamp + 300; // Add a buffer of 300 seconds (5 minutes)

        // Call the swapETHForTokens function from the ChainZoomVault contract
        uint256 amountBought = vault.swapETHForTokens(
            ethAmount,
            address(zoomToken),
            0, // Accept any amount of $ZOOM tokens
            address(vault),
            deadline
        );

        return amountBought;
    }

    // Allow the owner to set the launch time manually
    function setLaunchTime(uint256 _launchTime) external onlyOwner {
        require(launchTime == 0, "Launch time can only be set once");
        require(
            block.timestamp < _launchTime,
            "Launch time must be in the future"
        );
        launchTime = _launchTime;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getRoundEndTime(uint256 _round) public view returns (uint256) {
        return launchTime + (_round * ROUND_DURATION);
    }

    function getClaimPeriodEndTime() public view returns (uint256) {
        return lastRoundEndTime + CLAIM_PERIOD;
    }

    function getEarlyBirdEndTime() public view returns (uint256) {
        return launchTime + EARLY_BIRD_DURATION;
    }

    function setBronzeDuration(uint256 _duration) external onlyOwner {
        BRONZE_DURATION = _duration;
    }

    function setSilverDuration(uint256 _duration) external onlyOwner {
        SILVER_DURATION = _duration;
    }

    function setGoldDuration(uint256 _duration) external onlyOwner {
        GOLD_DURATION = _duration;
    }

    function setDiamondDuration(uint256 _duration) external onlyOwner {
        DIAMOND_DURATION = _duration;
    }

    function setBronzeF1Percent(uint256 _percent) external onlyOwner {
        BRONZE_F1_PERCENT = _percent;
    }

    function setBronzeF2Percent(uint256 _percent) external onlyOwner {
        BRONZE_F2_PERCENT = _percent;
    }

    function setSilverF1Percent(uint256 _percent) external onlyOwner {
        SILVER_F1_PERCENT = _percent;
    }

    function setSilverF2Percent(uint256 _percent) external onlyOwner {
        SILVER_F2_PERCENT = _percent;
    }

    function setGoldF1Percent(uint256 _percent) external onlyOwner {
        GOLD_F1_PERCENT = _percent;
    }

    function setGoldF2Percent(uint256 _percent) external onlyOwner {
        GOLD_F2_PERCENT = _percent;
    }

    function setDiamondF1Percent(uint256 _percent) external onlyOwner {
        DIAMOND_F1_PERCENT = _percent;
    }

    function setDiamondF2Percent(uint256 _percent) external onlyOwner {
        DIAMOND_F2_PERCENT = _percent;
    }

    function setEarlyBirdF3Percent(uint256 _percent) external onlyOwner {
        EARLY_BIRD_F3_PERCENT = _percent;
    }

    function setEarlyBirdDuration(uint256 _duration) external onlyOwner {
        EARLY_BIRD_DURATION = _duration;
    }

    function setRoundDuration(uint256 _duration) external onlyOwner {
        ROUND_DURATION = _duration;
    }

    function setMaxStakesPerUser(uint256 _maxStakes) external onlyOwner {
        MAX_STAKES_PER_USER = _maxStakes;
    }

    function setClaimPeriod(uint256 _period) external onlyOwner {
        CLAIM_PERIOD = _period;
    }

    function setAutoCompoundThreshold(uint256 _threshold) external onlyOwner {
        AUTO_COMPOUND_THRESHOLD = _threshold;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    mapping(uint256 => uint256) public roundTotalStaked;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
