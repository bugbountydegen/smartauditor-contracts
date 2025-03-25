// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { IClaiming } from "./IClaiming.sol";

/**
 * @title Staking contract interface.
 * @author DOP team.
 * @notice Interface for the Staking contract.
 */
interface IStaking {
    /* ========== FUNCTIONS ========== */

    /**
     * @notice Stake DOP tokens to earn rewards. Resets reward claim time.
     * CANNOT be called when paused.
     * @param amount Amount of DOP tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Submit a request to unstake your DOP tokens.
     * @dev Performs necessary checks on staker's stake and transfers unstaked
     * tokens to the Claim contract for further processing.
     */
    function requestUnstake(uint256 amount) external;

    /**
     * @notice Claim DOP token rewards. CANNOT be called when claim time is not
     * reached.
     */
    function claim() external;

    /**
     * @notice Claim and restake DOP token rewards. CAN be called when claim
     * time is not reached. Resets reward claim time. CANNOT be called when
     * paused.
     */
    function claimAndRestake() external;

    /**
     * @notice Updates the DOP token rewards wallet. Only `owner` can call this
     * function.
     * @param newRewardWallet Address of the new DOP token rewards wallet.
     */
    function updateRewardWallet(address newRewardWallet) external;

    /**
     * @notice Updates the Claiming contract. Only `owner` can call this
     * function.
     * @param newClaiming Address of the mew Claiming contract.
     */
    function updateClaiming(IClaiming newClaiming) external;

    /**
     * @notice Change the state of the contract from unpaused to paused. Only
     * `owner` can call this function.
     */
    function pause() external;

    /**
     * @notice Change the state of the contract from paused to unpaused. Only
     * `owner` can call this function.
     */
    function unpause() external;

    /**
     * @notice Gives the last reward time where reward is calculable.
     * @return lastTimeReward Time until DOP token rewards should be
     * calculated.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Gives the accumulated reward per DOP token staked.
     * @return rewardPerTokenStored Accumulated DOP token rewards per
     * individual DOP token staked.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Gives the DOP token reward for a given staker.
     * @param staker Staker to get reward for.
     * @return rewards Rewards calculated for the given staker.
     */
    function getReward(address staker) external view returns (uint256);
}
