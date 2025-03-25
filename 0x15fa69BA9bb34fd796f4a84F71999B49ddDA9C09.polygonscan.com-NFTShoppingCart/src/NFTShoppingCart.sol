// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./INFTCart.sol";

//beginning greater than end
error StartGreaterThanEnd(uint256 start, uint256 end);
//Zero quantity
error ZeroQuantity(uint256 qtd);

error InsufficientAmountPayment(uint256 valueTotal, uint256 valueSender);

error ZeroInvalidAddress(address adr);

contract NFTShoppingCart is Ownable, ReentrancyGuard {
    INFTCart private immutable nftSale;

    string private baseURI;
    uint256 private startTokenID;
    uint256 private endTokenID;
    uint256 public nextTokenID;
    uint256 public holderSalePrice;
    uint256 public pubSalePrice;
    uint256 public minHolderToken;
    address payable private ownerPay;

    event ChangePriceRulesEvent(uint256 holderSalePrice, uint256 pubSalePrice, uint256 minHolderToken);
    event ChangeStartEndEvent(uint256 start, uint256 end);

    constructor(
        address addrNftSale,
        uint256 start,
        uint256 end,
        address initialOwner,
        string memory uri,
        uint256 holderPrice,
        uint256 pubPrice,
        uint256 minToken
    ) Ownable(initialOwner) nonReentrant {
        checkStartEnd(start, end);

        if (addrNftSale == address(0)) {
            revert ZeroInvalidAddress(address(0));
        }

        if (initialOwner == address(0)) {
            revert ZeroInvalidAddress(address(0));
        }

        nftSale = INFTCart(addrNftSale);
        startTokenID = start;
        endTokenID = end;
        baseURI = uri;
        nextTokenID = start;
        ownerPay = payable(initialOwner);
        holderSalePrice = holderPrice;
        pubSalePrice = pubPrice;
        minHolderToken = minToken;
    }

    function buyNFT(uint256 qtd) external payable nonReentrant {
        require(qtd + nextTokenID <= (endTokenID + 1), "Insufficient tokens");

        if (qtd <= 0) {
            revert ZeroQuantity(qtd);
        }
        uint256 tokenID = nextTokenID;
        bytes memory bytesURI;
        address recipient = msg.sender;
        checkPayment(qtd, recipient, msg.value);

        for (uint256 i = 0; i < qtd; i++) {
            bytesURI = abi.encodePacked(baseURI, Strings.toString(tokenID), ".json");
            nftSale.mintOperator(tokenID, string(bytesURI), recipient);
            tokenID++;
        }

        nextTokenID = tokenID;
    }

    function whitdraw() external nonReentrant onlyOwner {
        uint256 amount = address(this).balance;
        Address.sendValue(ownerPay, amount);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setStartEnd(uint256 start, uint256 end) external nonReentrant onlyOwner {
        checkStartEnd(start, end);

        startTokenID = start;
        endTokenID = end;
        nextTokenID = start;

        emit ChangeStartEndEvent(start, end);
    }

    function setOwnerPay(address payAddr) external onlyOwner {
        if (payAddr == address(0)) {
            revert ZeroInvalidAddress(address(0));
        }
        ownerPay = payable(payAddr);
    }

    function setPricesRules(uint256 holderPrice, uint256 pubPrice, uint256 minToken) external onlyOwner {
        holderSalePrice = holderPrice;
        pubSalePrice = pubPrice;
        minHolderToken = minToken;

        emit ChangePriceRulesEvent(holderSalePrice, pubSalePrice, minHolderToken);
    }

    function checkStartEnd(uint256 start, uint256 end) internal pure {
        if (start > end) {
            revert StartGreaterThanEnd(start, end);
        }
    }

    function checkPayment(uint256 qtd, address recipient, uint256 vl) internal view {
        uint256 price = nftSale.balanceOf(recipient) >= minHolderToken ? holderSalePrice : pubSalePrice;
        uint256 priceTotal = price * qtd;

        if (priceTotal > vl) {
            revert InsufficientAmountPayment(priceTotal, vl);
        }
    }
}
