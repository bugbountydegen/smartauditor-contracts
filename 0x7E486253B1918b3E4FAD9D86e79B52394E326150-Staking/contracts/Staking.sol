// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { StakingErrors } from "./interfaces/Errors.sol";
import { IClaiming } from "./interfaces/IClaiming.sol";
import { IStaking } from "./interfaces/IStaking.sol";

/**
 * @title DOP Staking contract.
 * @author DOP team.
 * @notice Allows DOP tokens to be staked and rewarded.
 */
contract Staking is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    StakingErrors,
    IStaking
{
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @dev One year time in seconds.
    uint256 private constant _ONE_YEAR_TIME = 365 days;
    /// @dev Ninety days time in seconds.
    uint256 private constant _NINETY_DAYS_TIME = 90 days;
    /// @dev Magnitude at which accumulation is carried out.
    uint256 private constant _ACC_MAGNITUDE = 1e18;
    /// @notice Address of the DOP token contract.
    IERC20 public immutable DOP_TOKEN;
    /// @notice Time at which reward generation will stop.
    uint256 public immutable END_TIME;
    /// @notice DOP token rewards generated per second.
    uint256 public immutable REWARD_RATE;

    /// @notice Address of the DOP token rewards wallet.
    address public rewardWallet;
    /// @notice Address of the Claiming contract.
    IClaiming public claiming;
    /// @notice Time at which the last reward was updated.
    uint256 public lastUpdateTime;
    /// @notice Accumulated DOP token rewards per staked token.
    uint256 public rewardPerTokenStored;
    /// @notice Total DOP tokens staked in the contract.
    uint256 public totalStaked;

    /// @notice Staker's rewards. Triggers on each update call.
    mapping(address staker => uint256 rewards) public rewards;
    /// @notice Staker's stake data.
    mapping(address staker => Stake staking) public stakes;
    /// @notice Accumulated rewards per token already paid to each staker.
    mapping(address staker => uint256 rewardPerTokenPaid)
        public stakerRewardPerTokenPaid;

    /* ========== STRUCTS ========== */

    struct Stake {
        uint256 amount;
        uint256 restakedAmount;
        /// @dev Time after which rewards will be claimable.
        uint256 claimTime;
    }

    /* ========== EVENTS ========== */

    /// @dev Emitted when a stake has been performed.
    event Staked(address indexed staker, uint256 amount, uint256 claimTime);
    /// @dev Emitted when an unstake request has been issued.
    event UnstakeRequested(address indexed staker, uint256 amount);
    /// @dev Emitted when rewards have been claimed.
    event Claimed(address indexed staker, uint256 reward);
    /// @dev Emitted when a restake has been performed.
    event Restaked(address indexed staker, uint256 amount, uint256 claimTime);
    /// @dev Emitted when the DOP token rewards wallet is updated.
    event RewardWalletUpdated(
        address indexed oldRewardWallet,
        address indexed newRewardWallet
    );
    /// @dev Emitted when the Claiming contract is updated.
    event ClaimingUpdated(
        address indexed oldClaiming,
        address indexed newClaiming
    );

    /* ========== MODIFIERS ========== */

    /**
     * @dev Updates staker's DOP token rewards.
     */
    modifier updateReward() {
        _updateReward();
        _;
    }

    /**
     * @dev Implements staker's DOP token rewards updation logic.
     */
    function _updateReward() private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[msg.sender] = getReward(msg.sender);
        stakerRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
    }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor.
     * @param initDOPToken Address of the DOP token contract.
     * @param initRewardSupply DOP token rewards to be distributed in the given
     * time period.
     * @param initStartTime Time when reward generation will start.
     */
    constructor(
        IERC20 initDOPToken,
        uint256 initRewardSupply,
        uint256 initStartTime
    ) {
        if (address(initDOPToken) == address(0)) {
            revert InvalidAddress();
        }

        DOP_TOKEN = initDOPToken;
        END_TIME = initStartTime + _ONE_YEAR_TIME;
        REWARD_RATE = initRewardSupply / _ONE_YEAR_TIME;

        if (initRewardSupply == 0 || initStartTime == 0 || REWARD_RATE == 0) {
            revert InvalidAmount();
        }
    }

    /* ========== INITIALIZER ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     *
     * NOTE: This function can be maliciously front run after deployment,
     * however it should still be called atomically. In the case that it is
     * incorrectly initialized, no harm will be done since the contract can
     * always be abandoned.
     *
     * @param initOwner Address to initially transfer ownership to.
     * @param initRewardWallet Address of the DOP token rewards wallet.
     * @param initStartTime Time when reward generation will start.
     */
    function initialize(
        address initOwner,
        address initRewardWallet,
        uint256 initStartTime
    ) external initializer {
        __Staking_init(initOwner, initRewardWallet, initStartTime);
    }

    /**
     * @dev Initializes the contract by calling init functions, checking
     * initialization variables and finally setting them.
     * @param initOwner Address to initially transfer ownership to.
     * @param initRewardWallet Address of the DOP token rewards wallet.
     * @param initStartTime Time when reward generation will start.
     */
    function __Staking_init(
        address initOwner,
        address initRewardWallet,
        uint256 initStartTime
    ) internal onlyInitializing {
        __Staking_init_unchained(initOwner, initRewardWallet, initStartTime);
    }

    function __Staking_init_unchained(
        address initOwner,
        address initRewardWallet,
        uint256 initStartTime
    ) internal onlyInitializing {
        __Ownable_init(initOwner);
        __Pausable_init();
        __ReentrancyGuard_init();

        if (initRewardWallet == address(0)) {
            revert InvalidAddress();
        }

        if (initStartTime == 0) {
            revert InvalidAmount();
        }

        rewardWallet = initRewardWallet;
        lastUpdateTime = initStartTime;

        _pause();
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IStaking
     */
    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused updateReward {
        if (amount == 0) {
            revert InvalidAmount();
        }

        uint256 claimTime = _stake(msg.sender, amount, false);

        emit Staked({
            staker: msg.sender,
            amount: amount,
            claimTime: claimTime
        });
    }

    /**
     * @inheritdoc IStaking
     */
    function requestUnstake(uint256 amount) external nonReentrant updateReward {
        if (amount == 0) {
            revert InvalidAmount();
        }

        Stake memory staking = stakes[msg.sender];
        uint256 restakedAmount = staking.restakedAmount;
        uint256 unstakeableAmount = staking.amount - restakedAmount;

        if (block.timestamp >= staking.claimTime) {
            unstakeableAmount = staking.amount;

            if (restakedAmount > 0) {
                restakedAmount = amount > restakedAmount
                    ? 0
                    : restakedAmount - amount;
            }
        }

        if (amount > unstakeableAmount) {
            revert InvalidRequestUnstake(msg.sender, amount);
        }

        totalStaked -= amount;
        staking.amount -= amount;
        staking.restakedAmount = restakedAmount;
        stakes[msg.sender] = staking;
        claiming.setRequest(msg.sender, amount);

        emit UnstakeRequested({ staker: msg.sender, amount: amount });
    }

    /**
     * @inheritdoc IStaking
     */
    function claim() external nonReentrant updateReward {
        if (block.timestamp < stakes[msg.sender].claimTime) {
            revert ClaimTimeNotReached();
        }

        uint256 reward = _claim();
        DOP_TOKEN.safeTransferFrom(rewardWallet, msg.sender, reward);
    }

    /**
     * @inheritdoc IStaking
     */
    function claimAndRestake()
        external
        nonReentrant
        whenNotPaused
        updateReward
    {
        uint256 reward = _claim();
        uint256 claimTime = _stake(rewardWallet, reward, true);

        emit Restaked({
            staker: msg.sender,
            amount: reward,
            claimTime: claimTime
        });
    }

    /**
     * @inheritdoc IStaking
     */
    function updateRewardWallet(address newRewardWallet) external onlyOwner {
        if (rewardWallet == newRewardWallet) {
            revert IdenticalVariableAssignment();
        }

        emit RewardWalletUpdated({
            oldRewardWallet: rewardWallet,
            newRewardWallet: newRewardWallet
        });

        rewardWallet = newRewardWallet;
    }

    /**
     * @inheritdoc IStaking
     */
    function updateClaiming(IClaiming newClaiming) external onlyOwner {
        if (claiming == newClaiming) {
            revert IdenticalVariableAssignment();
        }

        emit ClaimingUpdated({
            oldClaiming: address(claiming),
            newClaiming: address(newClaiming)
        });

        if (address(claiming) != address(0)) {
            _provideAllowance(false);
        }

        claiming = newClaiming;
        _provideAllowance(true);
    }

    /**
     * @inheritdoc IStaking
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @inheritdoc IStaking
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IStaking
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < END_TIME ? block.timestamp : END_TIME;
    }

    /**
     * @inheritdoc IStaking
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                REWARD_RATE *
                _ACC_MAGNITUDE) / totalStaked);
    }

    /**
     * @inheritdoc IStaking
     */
    function getReward(address staker) public view returns (uint256) {
        return
            rewards[staker] +
            ((stakes[staker].amount *
                (rewardPerToken() - stakerRewardPerTokenPaid[staker])) /
                _ACC_MAGNITUDE);
    }

    /**
     * @dev Provides max allowance of DOP tokens in the staking contract to
     * the Claiming contract.
     * @param isAllowed State of whether the Claiming contract is allowed to
     * access this contracts DOP tokens.
     */
    function _provideAllowance(bool isAllowed) private {
        DOP_TOKEN.forceApprove(
            address(claiming),
            isAllowed ? type(uint256).max : 0
        );
    }

    /**
     * @dev Implements DOP token staking logic. DOES transfer staking DOP
     * tokens.
     * @param from Address to transfer DOP tokens from.
     * @param amount Amount of DOP tokens to stake.
     * @param isRestake Denotes whether the call is for a restake or a stake.
     * @return claimTime Time when rewards will be claimable.
     */
    function _stake(
        address from,
        uint256 amount,
        bool isRestake
    ) private returns (uint256) {
        totalStaked += amount;
        Stake memory staking = stakes[msg.sender];
        staking.amount += amount;

        if (isRestake) {
            staking.restakedAmount += amount;
        }

        staking.claimTime = block.timestamp + _NINETY_DAYS_TIME;
        stakes[msg.sender] = staking;
        DOP_TOKEN.safeTransferFrom(from, address(this), amount);

        return staking.claimTime;
    }

    /**
     * @dev Implements DOP token rewards claim logic. DOES NOT transfer
     * rewarding DOP tokens.
     * @return rewards Amount of DOP token rewards that need to be processed.
     */
    function _claim() private returns (uint256) {
        uint256 reward = rewards[msg.sender];

        if (reward == 0) {
            revert NoRewardToClaim();
        }

        delete rewards[msg.sender];

        emit Claimed({ staker: msg.sender, reward: reward });

        return reward;
    }

    /* ========== STORAGE GAP ========== */

    uint256[50] private _gap;
}
