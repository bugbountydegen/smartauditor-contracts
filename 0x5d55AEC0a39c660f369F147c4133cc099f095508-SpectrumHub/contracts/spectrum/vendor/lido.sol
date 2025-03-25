// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import { IERC20, IERC20Burnable, IERC20Permit, IERC20Rebased, IEcoERC4626 } from "../../eco-libs/token/ERC20/IERC20.sol";
import { EcoERC20Upgradeable } from "../../eco-libs/token/ERC20/EcoERC20Upgradeable.sol";
import { IWETH } from "../../eco-libs/token/ERC20/WETH.sol";
import { EcoERC20RebasedWithNative } from "../../eco-libs/token/ERC20/EcoERC20Rebased.sol";
import { EcoERC4626Upgradeable } from "../../eco-libs/token/ERC20/EcoERC4626Upgradeable.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

interface IstETH is IERC20Rebased {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256 stAmount);
}

interface IwstETH is IEcoERC4626 {
    function wrap(uint256 _stETHAmount) external returns (uint256 _wstETHAmount);

    function unwrap(uint256 _wstETHAmount) external returns (uint256 _stETHAmount);
}

contract STETH is IstETH, EcoERC20RebasedWithNative {
    constructor() {
        initEcoERC20Rebase(address(0), "Liquid staked Ether 2.0", "stETH", 18);
    }

    function getPooledEthByShares(uint256 _sharesAmount) external view override returns (uint256) {
        return calcBalance(_sharesAmount);
    }

    function getSharesByPooledEth(uint256 _pooledEthAmount) external view override returns (uint256) {
        return calcShare(_pooledEthAmount);
    }

    function submit(address) external payable override returns (uint256 stAmount) {
        stake(msg.value, _msgSender());
        return msg.value;
    }
}

contract WSTETH is IwstETH, EcoERC4626Upgradeable {
    constructor() {
        initEcoERC4626(IERC20(address(0)), "Wrapped liquid staked Ether 2.0", "wstETH");
    }

    function stETH() public view returns (IstETH) {
        return IstETH(asset());
    }

    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @dev Requirements:
     *  - `_stETHAmount` must be non-zero
     *  - msg.sender must approve at least `_stETHAmount` stETH to this
     *    contract.
     *  - msg.sender must have at least `_stETHAmount` of stETH.
     * User should first approve _stETHAmount to the WstETH contract
     * @return _wstETHAmount Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external override returns (uint256 _wstETHAmount) {
        return deposit(_stETHAmount, msg.sender);
    }

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return _stETHAmount Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external override returns (uint256 _stETHAmount) {
        return redeem(_wstETHAmount, msg.sender, msg.sender);
    }

    /**
     * @notice Shortcut to stake ETH and auto-wrap returned stETH
     */
    receive() external payable {
        stETH().submit{ value: msg.value }(address(0));
        _mint(msg.sender, previewDeposit(msg.value));
    }

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     * @param _stETHAmount amount of stETH
     * @return Amount of wstETH for a given stETH amount
     */
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {
        return stETH().getSharesByPooledEth(_stETHAmount);
    }

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     * @param _wstETHAmount amount of wstETH
     * @return Amount of stETH for a given wstETH amount
     */
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256) {
        return stETH().getPooledEthByShares(_wstETHAmount);
    }

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256) {
        return stETH().getPooledEthByShares(1 ether);
    }

    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of wstETH for a 1 stETH
     */
    function tokensPerStEth() external view returns (uint256) {
        return stETH().getSharesByPooledEth(1 ether);
    }

    function burn(uint256 amount) public virtual override(EcoERC4626Upgradeable, IERC20Burnable) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override(EcoERC4626Upgradeable, IERC20Burnable) {
        super.burnFrom(account, amount);
    }

    function nonces(address owner) public view virtual override(EcoERC4626Upgradeable, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
