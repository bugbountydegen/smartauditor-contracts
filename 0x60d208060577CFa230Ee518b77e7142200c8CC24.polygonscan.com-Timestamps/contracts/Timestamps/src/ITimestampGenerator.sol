// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ITimestampGenerator {
    function tokenURI(uint256 id, uint256 timestamp) external view returns (string memory);
}