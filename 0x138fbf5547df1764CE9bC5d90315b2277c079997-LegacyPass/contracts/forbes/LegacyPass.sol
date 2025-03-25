// SPDX-License-Identifier: MIT
/*
Forbes Legacy Pass Sale Agreement applies:
https://www.forbes.com/terms/legacy-pass-sale/ 
*/
pragma solidity ^0.8.20;

import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Pausable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import { ERC721URIStorage } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import { AccessControl } from '@openzeppelin/contracts/access/AccessControl.sol';
import { ERC5192 } from './ERC5192.sol';

contract LegacyPass is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Pausable,
  ERC5192,
  Ownable,
  ReentrancyGuard,
  AccessControl
{
  using Address for address;

  uint256 public immutable MAX_SUPPLY = 1917;
  uint256 public immutable PRICE = 0.33 ether;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  mapping(address => bool) allowlist;

  enum Stage {
    Initial,
    Private,
    Public
  }

  Stage public currentStage = Stage.Initial;
  string private baseURI;
  string private _contractURI;

  constructor() ERC5192('Forbes Legacy Pass', 'FORBES', true) Ownable(msg.sender) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    _contractURI = contractURI_;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
    super._increaseBalance(account, value);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), '.json'));
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC5192, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) {
    require(auth == address(0), 'This token is Soulbound Token, cannot be transferred');

    return super._update(to, tokenId, auth);
  }

  function nextStage() external onlyOwner {
    require(currentStage != Stage.Public, 'All stages have been completed');

    if (currentStage == Stage.Initial) {
      currentStage = Stage.Private;
    } else if (currentStage == Stage.Private) {
      currentStage = Stage.Public;
    }
  }

  function mint() external payable whenNotPaused {
    require(currentStage != Stage.Initial, 'Current stage is Initial stage, minting is not allowed in this stage');

    require(
      balanceOf(msg.sender) == 0,
      'This wallet already has an Legacy Pass, only one Legacy Pass per wallet is allowed'
    );

    if (currentStage == Stage.Private) {
      require(allowlist[msg.sender], 'Current stage is Private stage, only allowlisted wallets can mint in this stage');
      require(totalSupply() < MAX_SUPPLY - 20, 'Maximum NFTs have been minted in the private stage');
    }

    require(totalSupply() < MAX_SUPPLY, 'All NFTs have been minted');

    require(msg.value == PRICE, 'Invalid payment amount, Price is 0.33 ether');

    _safeMint(msg.sender, totalSupply() + 1);
  }

  function mint(address _userWallet, uint256) external payable whenNotPaused onlyRole(MINTER_ROLE) {
    require(_userWallet != address(0), 'Invalid wallet address');

    require(currentStage != Stage.Initial, 'Current stage is Initial stage, minting is not allowed in this stage');

    require(
      balanceOf(_userWallet) == 0,
      'This wallet already has an Legacy Pass, only one Legacy Pass per wallet is allowed'
    );

    if (currentStage == Stage.Private) {
      require(
        allowlist[_userWallet],
        'Current stage is Private stage, only allowlisted wallets can mint in this stage'
      );
      require(totalSupply() < MAX_SUPPLY - 20, 'Maximum NFTs have been minted in the private stage');
    }

    require(totalSupply() < MAX_SUPPLY, 'All NFTs have been minted');

    _safeMint(_userWallet, totalSupply() + 1);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function addToAllowlist(address[] memory wallets) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      allowlist[wallets[i]] = true;
    }
  }

  function removeFromAllowlist(address[] memory wallets) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      allowlist[wallets[i]] = false;
    }
  }

  function airdropToWallets(address[] memory wallets) external onlyOwner {
    require(totalSupply() + wallets.length <= MAX_SUPPLY, 'Wallets length exceeds the maximum supply');

    uint256 tokenId = totalSupply();

    for (uint256 i = 0; i < wallets.length; i++) {
      if (balanceOf(wallets[i]) > 0) {
        continue;
      }

      tokenId += 1;

      _safeMint(wallets[i], tokenId);
    }
  }

  function isSoldOut() external view returns (bool) {
    uint256 totalSupply = totalSupply();

    if (currentStage == Stage.Private) {
      return totalSupply == MAX_SUPPLY - 20;
    }

    return totalSupply == MAX_SUPPLY;
  }

  function isAllowList(address _wallet) external view returns (bool) {
    return allowlist[_wallet];
  }

  function withdraw(uint256 _value) external nonReentrant onlyOwner {
    Address.sendValue(payable(msg.sender), _value);
  }
}
