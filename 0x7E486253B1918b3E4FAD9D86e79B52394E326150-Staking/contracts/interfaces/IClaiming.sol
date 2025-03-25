// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

/**
 * @title Claiming contract interface.
 * @author DOP team.
 * @notice Interface for the Claiming contract.
 */
interface IClaiming {
    /* ========== FUNCTIONS ========== */

    /**
     * @notice Set a request to claim DOP tokens being unstaked from the Staking
     * contract. Only `staking` can call this function.
     * @param claimer Claimer who's DOP tokens are being held.
     * @param amount Amount of DOP tokens being unstaked.
     */
    function setRequest(address claimer, uint256 amount) external;

    /**
     * @notice Claim DOP tokens following the completion of a claim request.
     * @param index Claimer's index to claim request against.
     */
    function claimRequest(uint256 index) external;

    /**
     * @notice Claim DOP tokens following the completion of multiple claim
     * requests.
     * @param indexes List of claimer indexes to claim requests against.
     */
    function claimMultipleRequests(uint256[] calldata indexes) external;

    /**
     * @notice Gives the request pertaining to the given unique request index.
     * @param index Request index to get the key for.
     * @return amount Amount of DOP tokens requested.
     * @return claimRequestTime Time after which requested DOP tokens will be
     * claimable.
     */
    function getRequest(uint256 index) external view returns (uint256, uint256);

    /**
     * @notice Gives a unique key pertaining to the given unique request index.
     * @param index Request index to get the key for.
     * @return key Key that is present for the given request index.
     */
    function getRequestKey(uint256 index) external view returns (bytes32);
}
