// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

error ZeroAddress();
error MaxWalletCapExceeded();
error AddressNotWhitelisted();
error TradingAlreadyEnabled();
error TradingNotEnabled();

contract WiseMonkey is OFT {
    bool public tradingEnabled;
    uint16 public constant BASIS_POINTS = 10_000;
    uint16 public constant MAX_WALLET_CAP_BPS = 2; // 0.02%
    uint256 public launchTime;
    address public liquidityPair;

    event TradingEnabled(uint256 timestamp);
    event LiquidityPairSet(address indexed pair);
    event AddressesWhitelisted(address[] addresses);

    mapping(address account => bool isWhitelisted) public whitelistedAddresses;

    constructor(
        address _owner,
        uint256 _totalSupply,
        address _lzEndpoint
    )
        OFT("Wise Monkey", "MONKY", _lzEndpoint, _owner)
        Ownable(_owner)
    {
        _mint(_owner, _totalSupply);
    }

    function getMaxWalletAmount() public view returns (uint256) {
        return (totalSupply() * MAX_WALLET_CAP_BPS) / BASIS_POINTS;
    }

    // Can only be called once
    function enableTrading() external onlyOwner {
        if (tradingEnabled) revert TradingAlreadyEnabled();
        tradingEnabled = true;
        launchTime = block.timestamp;
        emit TradingEnabled(block.timestamp);
    }

    function setLiquidityPair(address _pair) external onlyOwner {
        if (_pair == address(0)) revert ZeroAddress();
        liquidityPair = _pair;
        whitelistedAddresses[_pair] = true;
        emit LiquidityPairSet(_pair);
    }

    function batchWhitelist(address[] calldata _addresses) external onlyOwner {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length;) {
            address _address = _addresses[i];
            whitelistedAddresses[_address] = true;
            unchecked {
                i++;
            }
        }
        emit AddressesWhitelisted(_addresses);
    }

    function _update(address _from, address _to, uint256 _amount) internal override {
        bool isTradingEnabled = tradingEnabled;
        bool isFromWhitelisted = whitelistedAddresses[_from];
        bool isToWhitelisted = whitelistedAddresses[_to];
        address _liquidityPair = liquidityPair;
        bool isFromLiquidityPair = _from == _liquidityPair;
        bool isToLiquidityPair = _to == _liquidityPair;
        address _owner = owner();
        bool isOwner = _from == _owner || _to == _owner;

        // Sniper trap
        if (!isTradingEnabled && isFromLiquidityPair && !isOwner) {
            revert TradingNotEnabled();
        }

        /*
        * Anti-bot/whale protection for the first 20 minutes after launch:
        * 1. Only whitelisted addresses can transfer tokens
        * 2. Maximum wallet cap of 0.1% of total supply is enforced
        */
        if (isTradingEnabled && block.timestamp < launchTime + 10 minutes) {
            bool isWhitelisted = isToWhitelisted || isFromWhitelisted;

            // Block non-whitelisted users from buying via the liquidity pair
            if (isFromLiquidityPair && !isToWhitelisted) {
                revert AddressNotWhitelisted();
            }

            // Block non-whitelisted users from selling to the liquidity pair
            if (isToLiquidityPair && !isFromWhitelisted) {
                revert AddressNotWhitelisted();
            }

            // If the address is not whitelisted and not the owner, revert
            if (!isWhitelisted && !isOwner) {
                revert AddressNotWhitelisted();
            }

            // If the receipt address is not the liquidity pair, check the max wallet cap
            if (!isToLiquidityPair && balanceOf(_to) + _amount > getMaxWalletAmount()) {
                revert MaxWalletCapExceeded();
            }
        }

        super._update(_from, _to, _amount);
    }
}
