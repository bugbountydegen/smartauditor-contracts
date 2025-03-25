// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {TokenHandler} from "../utils/TokenHandler.sol";
import {VaultStorageV1} from "./VaultStorage.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {IWETH} from "../interfaces/IWETH.sol";

/**
 * @title Vault Implementation
 * @author Immunefi
 * @notice Vaults are upgradeable. To not brick this, we use upgradeable libs and inherited storage
 */
contract Vault is VaultStorageV1, TokenHandler, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address private immutable implementation; // immutable vars dont occupy storage slots

    constructor() {
        implementation = address(this);
    }

    struct ERC20Payment {
        address token;
        uint256 amount;
    }

    event Withdraw();
    event PayWhitehat(address wh);

    /**
     * @dev Initializes the vault with a specified owner
     * @dev Can only be delegatecalled
     * @dev Requires WETH to be set up in the vault factory
     * @param _owner The address which will own the vault
     */
    function initialize(address _owner) public initializer {
        require(address(this) != implementation, "Vault: Can only be called by proxy");
        __Ownable_init();
        transferOwnership(_owner);
        vaultFactory = IVaultFactory(_msgSender());
        address _WETH = vaultFactory.WETH();
        require(_WETH != address(0), "WETH not setup");
        WETH = IWETH(_WETH);
    }

    /**
     * @notice Withdraws tokens to the owner account
     * @param payout The payout of tokens/token amounts to withdraw
     */
    function withdraw(ERC20Payment[] calldata payout) public onlyOwner {
        address owner = owner();
        uint256 length = payout.length;
        for (uint256 i; i < uint256(length); i++) {
            IERC20(payout[i].token).safeTransfer(owner, payout[i].amount);
        }
        emit Withdraw();
    }

    /**
     * @notice Pay a whitehat
     * @dev Only callable by owner
     * @param wh whitehat address
     * @param payout The payout of tokens/token amounts to withdraw
     */
    function payWhitehat(address wh, ERC20Payment[] calldata payout) public onlyOwner {
        address feeTo = vaultFactory.feeTo();
        uint256 length = payout.length;
        for (uint256 i; i < uint256(length); i++) {
            IERC20(payout[i].token).safeTransfer(feeTo, payout[i].amount / 10);
            IERC20(payout[i].token).safeTransfer(wh, payout[i].amount);
        }
        emit PayWhitehat(wh);
    }

    /**
     * @notice Converts eth to weth
     * @dev prevents bricking eth sent to this contract
     */
    receive() external payable {
        WETH.deposit{value: msg.value}();
    }
}
