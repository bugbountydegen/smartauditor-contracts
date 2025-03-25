// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
contract TokenHolder {
    mapping(address => bool) private owners;

    constructor(address owner) {
        owners[owner] = true;
        owners[msg.sender] = true;
    }

    function call(address target, bytes calldata data) external {
        require(owners[msg.sender], "only owner!");
        (bool success, ) = target.call(data);
        require(success, "call failed!");
    }
}
