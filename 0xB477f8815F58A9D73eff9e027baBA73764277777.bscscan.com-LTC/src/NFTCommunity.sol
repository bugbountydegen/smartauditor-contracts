// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Owned} from "@solmate-6.8.0/src/auth/Owned.sol";
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";
import {NFT} from "./abstract/token/NFT.sol";
import {_USDT} from "./utils/constant.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTCommunity is NFT {
    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;

    constructor(address _owner_) ERC721(unicode"TFT", "TFT") Owned(_owner_) {}

    function processALL() public {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 amount = IERC20(_USDT).balanceOf(address(this)) / shareholderCount;
        if (amount < 1 gwei) {
            return;
        }
        for (uint256 i = 0; i < shareholderCount; i++) {
            address holder = shareholders[i];
            IERC20(_USDT).transfer(holder, amount);
        }
    }

    function _beforeMintTo(address to) internal virtual override {
        addShareholder(to);
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) public onlyOwner {
        address lastLPHolder = shareholders[shareholders.length - 1];
        uint256 holderIndex = shareholderIndexes[shareholder];
        if (holderIndex == 0) return;
        shareholders[holderIndex] = lastLPHolder;
        shareholderIndexes[lastLPHolder] = holderIndex;
        shareholders.pop();
    }

    function removeShareholderByIndex(uint256 holderIndex) public onlyOwner {
        address lastLPHolder = shareholders[shareholders.length - 1];
        shareholders[holderIndex] = lastLPHolder;
        shareholderIndexes[lastLPHolder] = holderIndex;
        shareholders.pop();
    }

    function holderLength() external view returns (uint256) {
        return shareholders.length;
    }

    function emergencyWithdraw(IERC20 token, address to, uint256 _amount) external onlyOwner {
        token.transfer(to, _amount);
    }
}
