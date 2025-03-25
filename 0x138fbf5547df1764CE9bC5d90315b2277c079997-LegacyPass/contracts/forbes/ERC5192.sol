// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC5192 } from './IERC5192.sol';

abstract contract ERC5192 is ERC721Enumerable, IERC5192 {
  bool private immutable isLocked;

  error ErrLocked();
  error ErrNotFound();

  constructor(string memory _name, string memory _symbol, bool _isLocked) ERC721(_name, _symbol) {
    isLocked = _isLocked;
  }

  modifier checkLock() {
    if (isLocked) revert ErrLocked();
    _;
  }

  function locked(uint256 tokenId) external view returns (bool) {
    if (_ownerOf(tokenId) == address(0)) revert ErrNotFound();
    return isLocked;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
  }
}
