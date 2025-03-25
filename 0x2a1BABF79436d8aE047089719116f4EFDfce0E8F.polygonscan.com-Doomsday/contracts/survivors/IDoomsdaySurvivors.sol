// SPDX-License-Identifier: Shame

pragma solidity ^0.8.4;

interface IDoomsdaySurvivors {
    function balanceOf(address _owner) external view returns(uint);
    function ownerOf(uint _tokenId) external view returns(address);
    function saleActive() external view returns(bool);
    function totalSupply() external view returns(uint);

    function tokenToSurvivor(uint _tokenId) external view returns(uint);
    function tokenToBunker(uint _tokenId) external view returns(uint);
    function withdrawn(uint _tokenId) external view returns(bool);

}