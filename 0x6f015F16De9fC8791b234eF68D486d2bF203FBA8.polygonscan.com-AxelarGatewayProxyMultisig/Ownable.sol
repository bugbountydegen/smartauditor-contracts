// Root file: src/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'NOT_OWNER');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'ZERO_ADDR');

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
