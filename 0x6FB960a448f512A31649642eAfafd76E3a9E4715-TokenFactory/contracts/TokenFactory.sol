// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DegenUpLaunchpad.sol";

contract TokenFactory is Ownable {
    // Struct to store token information
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        string logoUrl; // Stores the token's logo as a URL (could be an IPFS hash)
        string website;
        string twitter;
        string telegram;
        address creator;
        uint256 createdAt; // New field to store the creation timestamp
    }

    // Mapping to store information about each token deployed
    mapping(address => TokenInfo) public tokenInfo;

    // Mapping to store the token contracts created by each creator
    mapping(address => address[]) public tokensCreatedByUser;

    // Array to store all token addresses created
    address[] public allTokens;

    event TokenCreated(
        address indexed creator,
        address tokenAddress,
        string name,
        string symbol,
        string logoUrl
    );

    // Constructor to initialize the factory contract
    constructor() Ownable(msg.sender) {}

    // Create a new token with additional information (logo, description, URLs)
    function createToken(
        string memory name,
        string memory symbol,
        string memory description,
        string memory logoUrl, // New field for token's logo image URL
        string memory website,
        string memory twitter,
        string memory telegram
    ) external payable returns (address) {
        // Deploy a new instance of the DegenUpLaunchpad contract for the new token
        DegenUpLaunchpad newToken = new DegenUpLaunchpad(name, symbol);

        // Store token information including the logo URL and creation timestamp
        tokenInfo[address(newToken)] = TokenInfo({
            name: name,
            symbol: symbol,
            description: description,
            logoUrl: logoUrl,
            website: website,
            twitter: twitter,
            telegram: telegram,
            creator: msg.sender,
            createdAt: block.timestamp // Set the creation timestamp
        });

        // Track tokens created by each user
        tokensCreatedByUser[msg.sender].push(address(newToken));

        // Track all tokens created
        allTokens.push(address(newToken));

        // Emit an event for tracking purposes
        emit TokenCreated(msg.sender, address(newToken), name, symbol, logoUrl);

        // If Ether is sent during token creation, calculate and buy tokens
        if (msg.value > 0) {
            // Call the buyTokens function on the newly created token contract
            (bool success, ) = address(newToken).call{value: msg.value}(
                abi.encodeWithSignature("buyTokens(address)", msg.sender)
            );
            require(success, "Token purchase failed");
        }

        return address(newToken);
    }

    // Get token information by token contract address
    function getTokenInfo(
        address tokenAddress
    ) external view returns (TokenInfo memory) {
        return tokenInfo[tokenAddress];
    }

    // New function to get tokens created by a user
    function getTokensCreatedByUser(
        address user
    ) external view returns (address[] memory) {
        return tokensCreatedByUser[user];
    }

    // New function to get all tokens created
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }
}
