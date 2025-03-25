// SPDX-License-Identifier: Mustard

pragma solidity ^0.8.4;

interface IDoomsdayCollectibles {
    function mint(address _to, uint cityId) external;

    function totalSupply() external view returns (uint256);
    function mintCount() external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
    function cityIds(uint256 _tokenId) external view returns (uint);

}