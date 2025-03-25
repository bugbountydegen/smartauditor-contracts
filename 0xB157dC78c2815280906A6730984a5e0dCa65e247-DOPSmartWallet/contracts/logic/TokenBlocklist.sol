// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Token Blocklist
/// @author DOP Team
/// @notice Blocklist of tokens that are incompatible with the protocol
/// @dev Tokens on this blocklist can't be encrypted to dop.
/// Tokens on this blocklist will still be transferrable internally (as internal transactions have a encrypted token ID) and
/// decryptable (to prevent user funds from being locked).
contract TokenBlocklist is OwnableUpgradeable {
    mapping(IERC20 => bool) public tokenBlocklist;

    /// @dev Emitted when token is added in blocklist
    event AddToBlocklist(IERC20 indexed token);

    /// @dev Emitted when token is removed from blocklist
    event RemoveFromBlocklist(IERC20 indexed token);

    /// @notice Adds tokens to Blocklist, only callable by owner (governance contract)
    /// @dev This function will ignore tokens that are already in the Blocklist no events will be emitted in this case
    /// @param tokens List of tokens to add to Blocklist
    function addToBlocklist(IERC20[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC20 token = tokens[i];
            if (!tokenBlocklist[token]) {
                tokenBlocklist[token] = true;

                emit AddToBlocklist({ token: token });
            }
        }
    }

    /// @notice Removes token from blocklist, only callable by owner (governance contract)
    /// @dev This function will ignore tokens that aren't in the blocklist no events will be emitted in this case
    /// @param tokens List of tokens to remove from blocklist
    function removeFromBlocklist(IERC20[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC20 token = tokens[i];
            if (tokenBlocklist[token]) {
                delete tokenBlocklist[token];

                emit RemoveFromBlocklist({ token: token });
            }
        }
    }

    uint256[50] private _gap;
}
