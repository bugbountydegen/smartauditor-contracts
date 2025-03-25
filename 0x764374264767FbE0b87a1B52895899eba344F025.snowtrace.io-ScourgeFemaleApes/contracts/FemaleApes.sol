// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC2981.sol";

contract ScourgeFemaleApes is ERC721Enumerable, Ownable, IERC2981 {
    using SafeMath for uint256;
    string public baseURL;
    using Counters for Counters.Counter;
    using Strings for *;

    Counters.Counter private _tokenIdTracker;
    mapping(address => uint8) private wls;
    mapping(address => uint8) private minters;

    bool public saleStarted = true;
    bool public whitelistOnly = false;

    constructor(string memory _baseURL) ERC721("Scourge Female Apes", "SFAPE") {
        baseURL = _baseURL;
    }

    function toggleSale() public onlyOwner {
        saleStarted = !saleStarted;
    }

    function toggleWl() public onlyOwner {
        whitelistOnly = !whitelistOnly;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURL;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURL, Strings.toString(tokenId), ".json")
            );
    }

    function batchAdd(address[] calldata addresses, uint8 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            wls[addresses[i]] = amount;
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            0x2Ae44E866d7Cd4bFD98c6417a455eBB901603Ba8,
            (value * 1000) / 10000
        );
    }

    function mint() public payable {
        require(saleStarted, "Sale is not active");
        require(
            _tokenIdTracker.current() + 393 <= 3233,
            "Purchase exceed max supply of tokens"
        );

        uint256 newTokenId = _tokenIdTracker.current();
        newTokenId = newTokenId + 392;

        if (whitelistOnly) {
            uint8 maxAmount = wls[msg.sender];
            uint8 currentAmount = minters[msg.sender];

            require(currentAmount < maxAmount, "Limit reached");

            _safeMint(_msgSender(), newTokenId);
            _tokenIdTracker.increment();

            minters[msg.sender] = currentAmount + 1;
        } else {
            uint8 currentAmount = minters[msg.sender];

            require(currentAmount < 10, "Limit reached");
            require(msg.value >= 0.1 ether, "Unsufficient funds");
            _safeMint(_msgSender(), newTokenId);
            _tokenIdTracker.increment();
            minters[msg.sender] = currentAmount + 1;
        }
    }

    function withdrawBalance() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Zero balance error.");
        _withdraw(
            0x8467CAa4B2EBf3FE001e5144E73fACa743556Bb6,
            balance.div(100).mul(25)
        );
        _withdraw(
            0x2Ae44E866d7Cd4bFD98c6417a455eBB901603Ba8,
            balance.div(100).mul(75)
        );
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function migrate(address _address, uint8 _tokenId) public onlyOwner {
        require(_tokenId < 392, "restricted");
        _safeMint(_address, _tokenId);
    }
}
