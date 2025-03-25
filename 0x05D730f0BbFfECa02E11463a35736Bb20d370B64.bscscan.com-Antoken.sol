// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Antoken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    string public name = "Antoken";
    string public symbol = "ANT";
    uint8 public decimals = 8;
    uint256 private _totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    address[] public _lpAddress;
    address private blackAddress = 0x0000000000000000000000000000000000000000;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, initialSupply * 10 ** uint256(decimals));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addLpAddress(address lpAddress) public onlyOwner {
        _lpAddress.push(lpAddress);
    }

    function removeLpAddress(address lpAddress) public onlyOwner {
        for (uint i = 0; i < _lpAddress.length; i++) {
            if (_lpAddress[i] == lpAddress) {
                _lpAddress[i] = _lpAddress[_lpAddress.length-1];
                _lpAddress.pop();
                return;
            }
        }
    }

    function checkLpAddress(address target,address target1) private view returns(bool) {
        for (uint i = 0; i < _lpAddress.length; i++) {
            if (target == _lpAddress[i] || target1 == _lpAddress[i]) {
                return true;
            }
        }
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "transfer to the zero address");
        require(balanceOf[sender] >= amount, "insufficient balance");

        bool bLp = checkLpAddress(sender,recipient);

        if (bLp) {
            uint256 burnAmount = (amount * 35) / 1000;
            uint256 transferAmount = amount - burnAmount;

            balanceOf[sender] -= amount;
            balanceOf[blackAddress] += burnAmount;
            balanceOf[recipient] += transferAmount;

            emit Transfer(sender, blackAddress, burnAmount);
            emit Transfer(sender, recipient, transferAmount);
        } else {
            balanceOf[sender] -= amount;
            balanceOf[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(amount <= allowance[sender][msg.sender], "transfer amount exceeds allowance");

        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "zero address");

        _totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "zero address");

        balanceOf[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}