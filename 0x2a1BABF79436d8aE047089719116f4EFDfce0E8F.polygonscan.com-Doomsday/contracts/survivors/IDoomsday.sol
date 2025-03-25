// SPDX-License-Identifier: Fear

pragma solidity ^0.8.4;

interface IDoomsday {
    enum Stage {Initial,PreApocalypse,Apocalypse,PostApocalypse}
    function stage() external view returns(Stage);
    function totalSupply() external view returns (uint256);
    function isVulnerable(uint _tokenId) external view returns(bool);

    function ownerOf(uint256 _tokenId) external view returns(address);

    function confirmHit(uint _tokenId) external;
}