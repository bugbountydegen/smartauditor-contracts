// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

/**
 * @title Generic errors.
 * @author DOP team.
 * @notice Errors being used in more than one contract.
 */
interface Errors {
    /**
     * @dev Indicates a failure with the given address, for example,
     * `address(0)`.
     */
    error InvalidAddress();
    /**
     * @dev Indicates an error related to the given amount, for example, `0`.
     */
    error InvalidAmount();
    /**
     * @dev Indicates an error if the variable being assigned is identical to
     * the old variable.
     */
    error IdenticalVariableAssignment();
}

/**
 * @title Staking errors.
 * @author DOP team.
 * @notice Errors being used only in the Staking contract.
 */
interface StakingErrors is Errors {
    /**
     * @dev Indicates an error related to ``staker``'s unstake request when the
     * amount of tokens staked is less than the `amount` requested to unstake.
     */
    error InvalidRequestUnstake(address staker, uint256 amount);
    /**
     * @dev Indicates an error related to staker's claim when the claim time
     * has not yet passed.
     */
    error ClaimTimeNotReached();
    /**
     * @dev Indicates an error related to staker's claim when there is no
     * amount of DOP token rewards to claim.
     */
    error NoRewardToClaim();
}

/**
 * @title Claiming errors.
 * @author DOP team.
 * @notice Errors being used only in the Claiming contract.
 */
interface ClaimingErrors is Errors {
    /**
     * @dev Indicates an error when the caller, `account`, is not authorized.
     */
    error ClaimingUnauthorizedAccount(address account);
    /**
     * @dev Indicates an error related to claimer's claim request when the
     * claim request time has not yet passed.
     */
    error ClaimRequestTimeNotReached();
    /**
     * @dev Indicates an error related to claimer's claim request when the
     * amount of tokens in the request is `0`.
     */
    error InvalidClaimRequest();
    /**
     * @dev Indicates a failure with the given array's length, i.e. array's
     * length is `0`.
     */
    error ZeroLengthArray();
}
