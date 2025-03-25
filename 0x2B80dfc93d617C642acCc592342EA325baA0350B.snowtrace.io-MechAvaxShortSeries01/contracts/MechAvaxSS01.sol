// SPDX-License-Identifier: MIT
// MechAvax ERC721A Contracts v0.0.1
// Creator: 0xBoots

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract MechAvaxShortSeries01 is ERC721A, ERC721AQueryable, ERC721ABurnable, AccessControl, ERC2981 {

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CFO_ROLE = keccak256("CFO_ROLE");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    uint96 public tokenRoyalties = 300; // 3% royalty
    address public royaltyPayout = 0x3eA83B008FE839466ee3d4c8070ae5CA5EF969d3;

    string public _revealedURI;
    string public _nonRevealedURI;

    bool public revealed = false;
    bool public mintOpen = false;

    uint256 public price = 1*1e17;
    uint256 public maxMint= 3;

    mapping(address => bool) public minted;
    uint256 public maxSupply = 2250;

    constructor() ERC721A("MechAvax ShortSeries #01", "MASS01") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(CFO_ROLE, msg.sender);
        _grantRole(DEV_ROLE, msg.sender);
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);

    }

    // MODIFIERS

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // OPEN MINT
    function openSale() external onlyRole(CFO_ROLE) {
        mintOpen = true;
    }

    function closeSale() external onlyRole(CFO_ROLE) {
        mintOpen = false;
    }

    function setMaxMint (uint256 _maxAmount) external onlyRole(CFO_ROLE){
        maxMint = _maxAmount;
    }

    function withdraw() external onlyRole(CFO_ROLE) {
        
        require(address(this).balance > 0, "Nothing to withdraw");

        require(payable(msg.sender).send(address(this).balance));
    }

    // BURN FUNCTION

    function burn (uint256 tokenId) public override(ERC721ABurnable) onlyRole(BURNER_ROLE){
        super.burn(tokenId);
    }

    // MINT FUNCTION

    function mint (uint256 _count) public payable callerIsUser{
        require(mintOpen, "Mint is not active");
        require(_count >= 1, "atleast 1");
        require (msg.value >= price*_count, "not enough avax");
        require (!minted[msg.sender], "already minted");
        require(_count <= maxMint, "trying to mint over max");
        require(totalSupply() + _count <= maxSupply,  "Sign Ups Have Closed");
        minted[msg.sender] = true;
        _mint(msg.sender, _count);
    }

    // URI FUNCTION

    function reveal() external onlyRole(DEV_ROLE) {
        revealed = true;
    }

    function setRevealedURI(string memory _uri) external onlyRole(DEV_ROLE){
        _revealedURI = _uri;
    }

    function setNONRevealedURI(string memory _uri) external onlyRole(DEV_ROLE){
        _nonRevealedURI = _uri;
    }


    function tokenURI (uint256 tokenId) override(ERC721A, IERC721A) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (revealed == true) {
            return _revealedURI;
            }

        else {
            return _nonRevealedURI;
        }
           
    }

    // INTERFACE SUPPORT

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return 
        ERC721A.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId) ||
        AccessControl.supportsInterface(interfaceId);
    }

    // ROYALTY FUNCTION

    function setTokenRoyalties(uint96 _royalties) external onlyRole(CFO_ROLE) {
        tokenRoyalties = _royalties;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }

    function setRoyaltyPayoutAddress(address _payoutAddress) external onlyRole(CFO_ROLE)
    {
        royaltyPayout = _payoutAddress;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }


}
