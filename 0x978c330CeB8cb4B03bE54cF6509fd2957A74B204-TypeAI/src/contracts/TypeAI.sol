// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Implementation of Type AI Staking Pool with fixed APY and lockup.

/// @notice imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
/// Customs
import {ITypeAI} from "./interfaces/ITypeAI.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";

contract TypeAI is ITypeAI, Ownable, ReentrancyGuard {
    /// Using the libraries.
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice STATE VARIABLES ///
    uint256 constant MULTIPLIER = 1e36;

    /// Holds the current fixed APR going on.
    uint256 public fixedAPR;
    /// Holds The current lock in period going on.
    uint256 public lockInPeriod;
    /// Holds the amount of token locked in the contract.
    uint256 private _totalValueLocked;
    /// Holds the total ETH deposited for reward.
    uint256 public totalETHDeposited;
    /// Holds the ETH amount per share as reward.
    uint256 public ethRewardsPerShare;
    /// Holds the total reward distributed among the stake holders.
    uint256 public totalRewardsDistributed;
    /// Holds the token address which is being staked.
    IERC20 public immutable token;
    /// Holds the dex router address.
    IUniswapV2Router immutable _router;

    /// Mapping between stakeHolder address to their details.
    mapping(address stakeHolder => StakeHolder details)
        private _stakeHolderDetailsOf;
    /// Map for tacking the stake holders.
    EnumerableMap.AddressToUintMap private _stakeHoldersMap;

    /// @notice Constructor ///

    /**
     * @notice constructor contains all the parameters of the staking platform.
     * @param _token The address of the token to be staked.
     * @param _fixedAPR The fixed APY (in %) 10 = 10%, 50 = 50%.
     * @param _lockInPeriod The lock in period in seconds.
     * @param router_ The UniswapV2 router address.
     */
    constructor(
        address _token,
        uint256 _fixedAPR,
        uint256 _lockInPeriod,
        address router_
    ) Ownable(_msgSender()) {
        /// validations
        if (_token == address(0) || (router_ == address(0)))
            revert TypeAI__ZeroAddress(msg.sender);
        if (_fixedAPR == 0) revert TypeAI__ZeroAPR(msg.sender);

        /// Updating the state.
        token = IERC20(_token);
        fixedAPR = _fixedAPR;
        lockInPeriod = _lockInPeriod;
        _router = IUniswapV2Router(router_);

        /// Emitting Events.
        emit APRUpdated(0, _fixedAPR);
        emit LockInPeriodUpdated(0, _lockInPeriod);
    }

    /// @notice READ METHODS ///

    /**
     * @notice Returns the no of stake holders currently staked.
     * @return count The count of the stake holders.
     */
    function noOfStakeHolders() public view returns (uint256 count) {
        return _stakeHoldersMap.length();
    }

    /**
     * @notice Returns the details about the `stakeHolder`.
     * @param stakeHolder address of the stake holder.
     * @return details The details about the `stakeHolder`.
     */
    function stakeHolderDetailsOf(
        address stakeHolder
    ) public view returns (StakeHolder memory details) {
        return _stakeHolderDetailsOf[stakeHolder];
    }

    /**
     * @notice Returns the total amount staked by `stakeHolder`.
     * @param stakeHolder address of the stake holder.
     * @return stakedAmount the total amount staked by `stakeHolder`.
     */
    function totalAmountStakedBy(
        address stakeHolder
    ) public view returns (uint256 stakedAmount) {
        return _stakeHolderDetailsOf[stakeHolder].amount;
    }

    /**
     * @notice Returns the total amount of `token` locked in the contract.
     * @return tvl the total amount of tokens locked.
     */
    function totalValueLocked() public view returns (uint256 tvl) {
        return _totalValueLocked;
    }

    /**
     * @notice Returns the claimable token amount as interest by the `stakeHolder`.
     * @param stakeHolder address of the stake holder.
     * @return claimableInterest The amount of interest gained by `stakeHolder`.
     */
    function claimableInterestGainedBy(
        address stakeHolder
    ) public view returns (uint256 claimableInterest) {
        return _calculateInterestGainedBy(stakeHolder);
    }

    /**
     * @notice Returns the realized ETH for the `stakeHolder`
     * @param stakeHolder The address of the stake holder.
     */
    function getRealizedETH(
        address stakeHolder
    ) public view returns (uint256 realizedETH) {
        /// Getting the stake holder details as memory.
        StakeHolder memory _holderDetails = _stakeHolderDetailsOf[stakeHolder];
        /// If stakeholder has no investment return.
        if (_holderDetails.amount == 0) return 0;

        /// Calculate and return realized ETH.
        uint256 earnedRewards = _cumulativeETHRewards(_holderDetails.amount);
        if (earnedRewards <= _holderDetails.unrealizedETH) return 0;
        return earnedRewards - _holderDetails.unrealizedETH;
    }

    /**
     * @notice Returns the stake holders addresses currently staked.
     * @return holders The stake holder addresses.
     */
    function getStakeHolders() public view returns (address[] memory holders) {
        /// Getting the no of stake holders.
        uint256 _noOfStakeHolders = _stakeHoldersMap.length();
        /// Adding stake holders into memory array.
        address[] memory _stakeHolders = new address[](_noOfStakeHolders);
        for (uint256 index; index < _noOfStakeHolders; index++) {
            (address _stakeHolder, ) = _stakeHoldersMap.at(index);
            _stakeHolders[index] = _stakeHolder;
        }
        // return _stakeHoldersMap.
        return _stakeHolders;
    }

    /// @notice WRITE METHODS ///

    /**
     * @notice Allows the owner to set the APY
     * @param newAPR, the new APY to be set (in %) 10 = 10%, 50 = 50
     */
    function updateAPR(uint8 newAPR) public onlyOwner {
        /// Change the APR
        uint256 _oldAPR = fixedAPR;
        fixedAPR = newAPR;
        /// Emitting `APRUpdated` event.
        emit APRUpdated(_oldAPR, newAPR);
    }

    /**
     * @notice Allows the owner to set the lock in period.
     * @param newLockInPeriod The new lock in period in seconds.
     */
    function updateLockInPeriod(uint256 newLockInPeriod) public onlyOwner {
        /// Change the Lock in period.
        uint256 _oldLockInPeriod = lockInPeriod;
        lockInPeriod = newLockInPeriod;
        /// Emitting `LockInPeriodUpdated` event.
        emit LockInPeriodUpdated(_oldLockInPeriod, newLockInPeriod);
    }

    /**
     * @notice Allows a stake holder to stake tokens.
     * @dev Internally calls `_stake` function.
     * @param amount The amount to be deposited.
     */
    function stake(uint256 amount) public nonReentrant {
        _stake(amount);
    }

    /**
     * @notice Allows a user to withdraw its initial deposit.
     * @param amount The amount to withdraw.
     * @dev `amount` must be higher than `0`.
     * @dev `amount` must be lower or equal to the amount staked.
     * @dev Updating the stake holderVARIABLES claim rewards if rewards to claim.
     */
    function unstake(uint256 amount) public nonReentrant {
        /// Getting the stake holder details as storage.
        StakeHolder storage _stakeHolder = _stakeHolderDetailsOf[_msgSender()];

        /// Validations
        if (_stakeHolder.wallet == address(0))
            revert TypeAI__NotAStakeHolder(_msgSender());
        if ((_stakeHolder.stakedOn + lockInPeriod) >= block.timestamp)
            revert TypeAI__UnderLockInPeriod(_stakeHolder.wallet);
        if (amount == 0)
            revert TypeAI__AmountMustBeGreaterThanZero(_stakeHolder.wallet);
        if (amount > _stakeHolder.amount)
            revert TypeAI__InsufficientDepositAmount(_stakeHolder.wallet);

        /// TOKEN APR ///
        /// Updating the claimable interest
        _updateClaimableInterestOf(_stakeHolder.wallet);
        /// Claim interest If any claim amount available.
        if (_stakeHolder.claimableInterest > 0)
            _claimGainedInterest(_stakeHolder.wallet);

        /// Distribute ETH REWARDS ///
        uint256 _realizedETH = getRealizedETH(_stakeHolder.wallet);
        bool _otherStakersPresent = (_totalValueLocked - amount) > 0;
        if (!_otherStakersPresent) {
            _distributeETHRewards(_stakeHolder.wallet, false, 0);
        }

        /// Updating the TVL & stake holder balance.
        _totalValueLocked -= amount;
        _stakeHolder.amount -= amount;

        /// Update ETH Rewards per share ///
        _updateUnrealizedETHRewardsOf(_stakeHolder.wallet);
        if (_otherStakersPresent && (_realizedETH > 0))
            _depositETHRewards(_realizedETH);

        /// Removing from stake holders map.
        if (_stakeHolder.amount == 0)
            _stakeHoldersMap.remove(_stakeHolder.wallet);

        /// Transferring the tokens.
        token.safeTransfer(_stakeHolder.wallet, amount);
        /// Emitting `Withdrawn` event.
        emit Withdrawn(_stakeHolder.wallet, amount);
    }

    /**
     * @notice Claim all remaining balance on the contract
     * Residual balance is all the remaining tokens that have not been distributed
     * (e.g, in case the number of stakeholders is not sufficient)
     * @dev Can only be called after the end of the staking period
     * Cannot claim initial stakeholders deposit
     */
    function withdrawResidualBalance() public onlyOwner nonReentrant {
        uint256 residualBalance = token.balanceOf(address(this)) -
            _totalValueLocked;
        if (residualBalance == 0) revert TypeAI__InsufficientResidualBalance();
        /// Transfer the tokens.
        token.safeTransfer(_msgSender(), residualBalance);
    }

    /**
     * @notice Claims pending tokens gained as interest.
     * @dev Transfers the gained tokens to the `msg.sender/caller`
     */
    function claimGainedInterest() public nonReentrant {
        /// Validation for unknown caller.
        if (_stakeHolderDetailsOf[_msgSender()].wallet == address(0))
            revert TypeAI__NotAStakeHolder(_msgSender());
        /// Claim interest.
        _claimGainedInterest(_msgSender());
    }

    /**
     * @notice Claims pending ETH reward and re lock the stake for another lock-in-period.
     * @dev Distribute ETH reward with no compound.
     */
    function claimETHAndReLock() public nonReentrant {
        _distributeETHRewards(_msgSender(), false, 0);
    }

    /**
     * @notice Claims pending ETH reward and convert into `token` and then re-stake for another lock-in-period.
     * @dev Convert ETH reward to `token` and re invest.
     * @param _minReceive The min receive from dex.
     */
    function compoundETHAndReLock(uint256 _minReceive) public nonReentrant {
        _distributeETHRewards(_msgSender(), true, _minReceive);
    }

    /**
     * @notice Deposit ETH rewards into contract.
     * @dev Internally calls `_depositETHRewards`.
     */
    function depositETHRewards() public payable nonReentrant {
        _depositETHRewards(msg.value);
    }

    /// @notice Private Functions ///

    /**
     * @notice Returns the ETH reward amount based on `_share`.
     * @param _share The share/deposited amount of the stake holder.
     */
    function _cumulativeETHRewards(
        uint256 _share
    ) private view returns (uint256 ethRewards) {
        return (_share * ethRewardsPerShare) / MULTIPLIER;
    }

    /**
     * @notice Deposit ETH for giving reward to others.
     * @param _amountETH The amount of ETH wants to distribute.
     */
    function _depositETHRewards(uint256 _amountETH) private {
        /// Validations
        if (_amountETH == 0)
            revert TypeAI__AmountMustBeGreaterThanZero(_msgSender());
        if (_totalValueLocked == 0) revert TypeAI_NoTVLAvailable(_msgSender());

        /// Recalculate eth per share.
        totalETHDeposited += _amountETH;
        ethRewardsPerShare += (MULTIPLIER * _amountETH) / _totalValueLocked;
        /// Emit `DepositedETHRewards` event.
        emit DepositedETHRewards(_msgSender(), _amountETH);
    }

    /**
     * @notice Swap ETH for `token` into Uniswap and then reinvest.
     * @param _amount The amount of ETH wanted to swap.
     * @param _minTokensToReceive The minimum receivable `token` amount for ETH.
     */
    function _compoundETHRewards(
        uint256 _amount,
        uint256 _minTokensToReceive
    ) private {
        /// Setting up the swap path.
        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = address(token);

        /// Swap ETH for `token`
        uint256 _tokenBalBefore = token.balanceOf(address(this));
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _amount
        }(_minTokensToReceive, path, address(this), block.timestamp);

        /// Reinvest the compound amount.
        uint256 _compoundAmount = token.balanceOf(address(this)) -
            _tokenBalBefore;
        _stake(_compoundAmount);
    }

    /**
     * @notice Distribute ETH reward to `stakeHolder`.
     * @param stakeHolder The stake holder address to whom rewards distributed.
     * @param isReinvest If stake holder wants to reinvest ETH.
     * @param minReceive Minimum receivable for dex if stake holder wants to reinvest.
     */
    function _distributeETHRewards(
        address stakeHolder,
        bool isReinvest,
        uint256 minReceive
    ) private {
        /// Getting the stake holder details as memory.
        StakeHolder storage _holderDetails = _stakeHolderDetailsOf[stakeHolder];
        /// If stakeholder has no investment return.
        if (_holderDetails.amount == 0) return;

        /// Updating stake holder details.
        uint256 _realizedETH = getRealizedETH(_holderDetails.wallet);
        _holderDetails.realizedETH += _realizedETH;
        _holderDetails.stakedOn = block.timestamp; /// Re lock.
        _updateUnrealizedETHRewardsOf(_holderDetails.wallet);

        if (_realizedETH > 0) {
            /// Updating the total reward distributed.
            totalRewardsDistributed += _realizedETH;

            /// Compound and reinvest.
            if (isReinvest)
                _compoundETHRewards(_realizedETH, minReceive);
                /// Claim normal ETH rewards.
            else {
                /// Transferring the ETH.
                uint256 _ethBalanceBefore = address(this).balance;
                (bool success, ) = payable(_holderDetails.wallet).call{
                    value: _realizedETH
                }("");
                /// Validations
                if (!success)
                    revert TypeAI__ETHTransferFailed(
                        _holderDetails.wallet,
                        _realizedETH
                    );
                if (address(this).balance < (_ethBalanceBefore - _realizedETH))
                    revert TypeAI__InvalidETHBalance(
                        _holderDetails.wallet,
                        _realizedETH
                    );
            }

            /// Emitting `ETHRewardDistributed` event.
            emit ETHRewardDistributed(_holderDetails.wallet, _realizedETH);
        }
    }

    /**
     * @notice Allows a stake holder to stake tokens.
     * @dev Stake holder must first approve the `_amount` to stake before calling this function.
     * @param _amount The amount to be deposited.
     * @dev That the `amount` deposited should greater than 0.
     */
    function _stake(uint256 _amount) private {
        /// Validations
        if (_amount == 0)
            revert TypeAI__AmountMustBeGreaterThanZero(_msgSender());

        /// Transferring the tokens.
        token.safeTransferFrom(_msgSender(), address(this), _amount);

        /// Getting the stake holder details as storage.
        StakeHolder storage _stakeHolder = _stakeHolderDetailsOf[_msgSender()];

        /// If stake holder is staking for the first time.
        if (_stakeHolder.wallet == address(0))
            _stakeHolder.wallet = _msgSender();
        if (_stakeHolder.aprStartedOn == 0)
            _stakeHolder.aprStartedOn = block.timestamp;

        /// Update the interest of stake holder
        _updateClaimableInterestOf(_stakeHolder.wallet);

        // Distribute ETH Rewards.
        if (_stakeHolder.amount > 0)
            _distributeETHRewards(_stakeHolder.wallet, false, 0);

        /// Updating the TVL, stake holder balance & address.
        _totalValueLocked += _amount;
        _stakeHolder.amount += _amount;
        _stakeHolder.stakedOn = block.timestamp;
        /// Adding into stake holders map.
        _stakeHoldersMap.set(_stakeHolder.wallet, _amount);

        /// ETH Rewards
        _updateUnrealizedETHRewardsOf(_stakeHolder.wallet);

        /// Emitting `Deposited` event.
        emit Deposited(_stakeHolder.wallet, _amount);
    }

    /**
     * @notice Calculate the gained interest based on the `fixedAPR`.
     * @param _stakeHolder The address of the stake holder.
     * @return claimableInterest amount of claimable tokens as interest of the `_stakeHolder`
     */
    function _calculateInterestGainedBy(
        address _stakeHolder
    ) private view returns (uint256 claimableInterest) {
        /// Getting the stake holder details as memory.
        StakeHolder memory _holderDetails = _stakeHolderDetailsOf[_stakeHolder];

        /// Calculating the staking duration.
        uint256 _stakingDuration = block.timestamp -
            _holderDetails.aprStartedOn;
        /// Returns the claimable interest.
        return
            ((_holderDetails.amount * fixedAPR * _stakingDuration) /
                365 days /
                100) + _holderDetails.claimableInterest;
    }

    /**
     * @notice Claims pending interest.
     * @dev Transfer the pending interest to the `_stakeHolder` address.
     * @param _stakeHolder The address of the stake holder.
     */
    function _claimGainedInterest(address _stakeHolder) private {
        /// Getting the stake holder details as storage.
        StakeHolder storage _holderDetails = _stakeHolderDetailsOf[
            _stakeHolder
        ];
        /// @dev Updating the claimable interest.
        _updateClaimableInterestOf(_stakeHolder);

        /// @dev Checking if any claimable amount available.
        uint256 _claimableInterest = _holderDetails.claimableInterest;
        if (_claimableInterest == 0)
            revert TypeAI__NoInterestGained(_stakeHolder);

        if (token.balanceOf(address(this)) < _claimableInterest)
            revert TypeAI__InsufficientRewardPresent(
                _stakeHolder,
                _claimableInterest
            );
        if (
            (token.balanceOf(address(this)) - _claimableInterest) <
            _totalValueLocked
        )
            revert TypeAI__InsufficientRewardPresent(
                _stakeHolder,
                _claimableInterest
            );

        /// Removing the claimable amount.
        delete _holderDetails.claimableInterest;

        /// @dev Transfer the interest and emitting the event.
        token.safeTransfer(_stakeHolder, _claimableInterest);
        /// Emitting `InterestClaimed` event.
        emit InterestClaimed(_stakeHolder, _claimableInterest);
    }

    /**
     * @notice Updates gained interest and shift them to `rewardsToClaim`
     * @dev Recalculate the gained amount and resetting the stake time.
     */
    function _updateClaimableInterestOf(address _stakeHolder) private {
        /// Getting the stake holder details as storage.
        StakeHolder storage _holderDetails = _stakeHolderDetailsOf[
            _stakeHolder
        ];

        /// @dev Recalculating the claimable amount of `_stakeHolder`.
        _holderDetails.claimableInterest = _calculateInterestGainedBy(
            _stakeHolder
        );
        /// @dev Resetting the stake time.
        _holderDetails.aprStartedOn = block.timestamp;
    }

    /**
     * @notice Updates gained interest and shift them to `rewardsToClaim`
     * @dev Recalculate the gained amount and resetting the stake time.
     */
    function _updateUnrealizedETHRewardsOf(address _stakeHolder) private {
        /// Getting the stake holder details as storage.
        StakeHolder storage _holderDetails = _stakeHolderDetailsOf[
            _stakeHolder
        ];

        /// @dev Recalculating the unrealized ETH amount of `_stakeHolder`.
        _holderDetails.unrealizedETH = _cumulativeETHRewards(
            _holderDetails.amount
        );
    }
}
