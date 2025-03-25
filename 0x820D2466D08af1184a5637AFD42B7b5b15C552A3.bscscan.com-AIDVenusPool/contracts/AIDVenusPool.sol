// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./TokenHolder.sol";

interface VBep20Delegator {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOfUnderlying(address owner) external returns (uint);
    function mintBehalf(address receiver, uint mintAmount) external returns (uint);
    function redeemBehalf(address redeemer, uint redeemTokens) external returns (uint);
    function redeemUnderlyingBehalf(address redeemer, uint redeemAmount) external returns (uint);
}

interface ITokenHolder {
    function call(address target, bytes calldata data) external;
}

contract AIDVenusPool is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    VBep20Delegator public constant VUSDT = VBep20Delegator(0xfD5840Cd36d94D7229439859C0112a4185BC0255);
    address[] private holders;

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ERC20Upgradeable(USDT).approve(address(VUSDT), type(uint256).max);
        VUSDT.approve(address(VUSDT), type(uint256).max);
    }

    function setHolders(address[] calldata _holders) external onlyRole(DEFAULT_ADMIN_ROLE) {
        holders = _holders;
    }

    function batchAddHolder(uint256 size) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < size; i++) {
            _addHolder();
        }
    }

    function _addHolder() internal {
        TokenHolder holder = new TokenHolder(msg.sender);
        holders.push(address(holder));
    }

    function mint(uint256 mintAmount) internal {
        if (mintAmount == 0) {
            mintAmount = ERC20Upgradeable(USDT).balanceOf(address(this));
        }
        if (holders.length == 0) {
            VUSDT.mint(mintAmount);
        } else {
            uint256 idx = getRandomIndex(holders.length, mintAmount);
            VUSDT.mintBehalf(holders[idx], mintAmount);
        }
    }

    function getRandomIndex(uint256 max, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), salt))) % max;
    }

    function redeemUnderlying(uint256 redeemAmount) external onlyRole(OPERATOR_ROLE) {
        uint256 idx = getRandomIndex(holders.length, redeemAmount);
        VUSDT.redeemUnderlyingBehalf(holders[idx], redeemAmount);
        ERC20Upgradeable(USDT).transfer(msg.sender, redeemAmount);
    }

    function mint(uint256 poolId, uint256 mintAmount) external onlyRole(MINT_ROLE) {
        if (poolId == 0) {
            mint(mintAmount);
        }
    }
}
