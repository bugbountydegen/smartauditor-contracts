// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title Protection
/// @author Chainalysis team
/// @notice List for sanctioned addresses
interface Protection {
    /// @notice Checks whether a given address is sanctioned or not
    /// @param addr - Address to process
    function isSanctioned(address addr) external view returns (bool);
}
