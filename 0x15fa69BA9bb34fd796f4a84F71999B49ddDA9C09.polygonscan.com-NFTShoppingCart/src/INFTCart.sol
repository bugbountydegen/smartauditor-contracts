// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface INFTCart {
    function mintOperator(uint256 tokenID, string memory tokenUri, address recipient) external;

    function transferOperator(address newOperator) external;

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 id) external view returns (address owner);

    function balanceOf(address account) external view returns (uint256);
}
