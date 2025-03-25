// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import { IERC20, IERC20Burnable, IERC20Permit, IEcoERC4626, IERC20Rebased } from "../../eco-libs/token/ERC20/IERC20.sol";
import { ERC20RebasedUpgradeable, EcoERC20RebasedWithNative } from "../../eco-libs/token/ERC20/EcoERC20Rebased.sol";
import { IWETH, WrappingNativeCoin } from "../../eco-libs/token/ERC20/WETH.sol";
import { EcoERC4626Upgradeable } from "../../eco-libs/token/ERC20/EcoERC4626Upgradeable.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { IstETH } from "./lido.sol";

interface IeETH is IERC20Rebased {
    function shares(address _user) external view returns (uint256);

    // function initialize(address _liquidityPool) external;

    function mintShares(address _user, uint256 _share) external payable;

    function burnShares(address _user, uint256 _share) external payable;

    // function increaseAllowance(address _spender, uint256 _increaseAmount) external returns (bool);
    // function decreaseAllowance(address _spender, uint256 _decreaseAmount) external returns (bool);
}

interface IweETH is IEcoERC4626 {
    function wrap(uint256 _eETHAmount) external returns (uint256);

    function unwrap(uint256 _weETHAmount) external returns (uint256);

    function getWeETHByeETH(uint256 _eETHAmount) external view returns (uint256);

    function getEETHByWeETH(uint256 _weETHAmount) external view returns (uint256);
}

// ETH -> eETH
interface ILiquidityPool {
    function deposit() external payable returns (uint256);

    function sharesForAmount(uint256 _eETHAmount) external view returns (uint256);

    function amountForShare(uint256 _weETHAmount) external view returns (uint256);

    function eETH() external view returns (IeETH);
}

// eETH -> eETH
interface ILiquifier {
    function depositWithERC20(address _token, uint256 _amount, address _referral) external returns (uint256);

    function liquidityPool() external returns (ILiquidityPool);
}

contract LiquidityPool is ILiquidityPool {
    IeETH public override eETH;

    function initLiquidityPool(IeETH _eETH) external {
        eETH = _eETH;
    }

    function deposit() external payable returns (uint256) {
        eETH.mintShares{ value: msg.value }(msg.sender, msg.value);
        return msg.value;
    }

    function sharesForAmount(uint256 _eETHAmount) external view returns (uint256) {
        return eETH.calcShare(_eETHAmount);
    }

    function amountForShare(uint256 _weETHAmount) external view returns (uint256) {
        return eETH.calcBalance(_weETHAmount);
    }
}

contract Liquifier is ILiquifier {
    ILiquidityPool public override liquidityPool;
    IeETH public eETH;
    IstETH public stETH;

    function initLiquifier(ILiquidityPool _liquidityPool, IeETH _eETH, IstETH _stETH) external {
        liquidityPool = _liquidityPool;
        eETH = _eETH;
        stETH = _stETH;
    }

    function depositWithERC20(address, uint256 _amount, address) external returns (uint256) {
        stETH.transferFrom(msg.sender, address(this), _amount);
        stETH.unstake(_amount, address(this));
        eETH.mintShares{ value: _amount }(msg.sender, _amount);
        return _amount;
    }

    receive() external payable {
        require(msg.sender == address(eETH) || msg.sender == address(stETH), "receive()");
    }
}

contract EETH is IeETH, EcoERC20RebasedWithNative {
    constructor() {
        initEcoERC20Rebase(address(0), "ether.fi ETH", "eETH", 18);
    }

    function shares(address _user) external view override returns (uint256) {
        return shareOf(_user);
    }

    function mintShares(address _user, uint256 _share) external payable override {
        stake(_share, _user);
    }

    function burnShares(address _user, uint256 _share) external payable override {
        unstake(_share, _user);
    }
}

contract WEETH is IweETH, EcoERC4626Upgradeable {
    constructor() {
        initEcoERC4626(IERC20(payable(address(0))), "Wrapped eETH", "weETH");
    }

    function eETH() public view returns (IeETH) {
        return IeETH(asset());
    }

    /**
     * @notice Exchanges eETH to weETH
     * @param _eETHAmount amount of eETH to wrap in exchange for weETH
     * @dev Requirements:
     *  - `_eETHAmount` must be non-zero
     *  - msg.sender must approve at least `_eETHAmount` eETH to this
     *    contract.
     *  - msg.sender must have at least `_eETHAmount` of eETH.
     * User should first approve _eETHAmount to the WeETH contract
     * @return _weETHAmount Amount of weETH user receives after wrap
     */
    function wrap(uint256 _eETHAmount) external returns (uint256 _weETHAmount) {
        return deposit(_eETHAmount, msg.sender);
    }

    /**
     * @notice Exchanges weETH to eETH
     * @param _weETHAmount amount of weETH to uwrap in exchange for eETH
     * @dev Requirements:
     *  - `_weETHAmount` must be non-zero
     *  - msg.sender must have at least `_weETHAmount` weETH.
     * @return _eETHAmount Amount of eETH user receives after unwrap
     */
    function unwrap(uint256 _weETHAmount) external returns (uint256 _eETHAmount) {
        return redeem(_weETHAmount, msg.sender, msg.sender);
    }

    /**
     * @notice Get amount of weETH for a given amount of eETH
     * @param _eETHAmount amount of eETH
     * @return _weETHAmount Amount of weETH for a given eETH amount
     */
    function getWeETHByeETH(uint256 _eETHAmount) public view returns (uint256 _weETHAmount) {
        return previewDeposit(_eETHAmount);
    }

    /**
     * @notice Get amount of eETH for a given amount of weETH
     * @param _weETHAmount amount of weETH
     * @return _eETHAmount Amount of eETH for a given weETH amount
     */
    function getEETHByWeETH(uint256 _weETHAmount) public view returns (uint256 _eETHAmount) {
        return previewRedeem(_weETHAmount);
    }

    /**
     * @notice Get amount of eETH for a one weETH
     * @return _weETHAmount Amount of eETH for 1 weETH
     */
    function eETHPerToken() external view returns (uint256 _weETHAmount) {
        return previewDeposit(1 ether);
    }

    /**
     * @notice Get amount of weETH for a one eETH
     * @return _eETHAmount Amount of weETH for a 1 eETH
     */
    function tokensPerEEth() external view returns (uint256 _eETHAmount) {
        return previewRedeem(1 ether);
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
