// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Owned} from "@solmate-6.8.0/src/auth/Owned.sol";
import "@openzeppelin-contracts-5.0.2/utils/Strings.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract NFT is ERC721Enumerable, Owned {
    string public baseURI = "";
    uint256 public currentTokenId;

    function _beforeMintTo(address to) internal virtual {}

    function mintTo(address recipient) public onlyOwner returns (uint256) {
        uint256 newItemId = ++currentTokenId;
        _beforeMintTo(recipient);
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function mintToMultiple(address[] memory recipients) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 newItemId = ++currentTokenId;
            _beforeMintTo(recipients[i]);
            _safeMint(recipients[i], newItemId);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
    }
}
