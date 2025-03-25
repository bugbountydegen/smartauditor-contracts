// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";
import { ISpectrumHubState, SpectrumHubState } from "./SpectrumHubState.sol";

import { ISpectrumCoreEntry } from "../core/SpectrumCoreEntry.sol";
import { IeETH, IweETH, ILiquidityPool, ILiquifier } from "../vendor/etherfi.sol";
import { IstETH, IwstETH } from "../vendor/lido.sol";

abstract contract SpectrumHubUtils is SpectrumHubState {
    // ---------------------- Convert for Stake ----------------------
    function _convertWEETHToSPETH(
        address asset,
        address actionForStake,
        uint256 amount
    ) internal returns (uint256 resultAmount) {
        IEcoERC20(asset).approve(actionForStake, amount);
        resultAmount = ISpectrumCoreEntry(actionForStake).stake(asset, address(this), amount);
    }

    function _convertEETHToWEETH(
        address asset,
        address actionForStake,
        uint256 amount
    ) internal returns (uint256 resultAmount) {
        IeETH(asset).approve(actionForStake, amount);
        resultAmount = IweETH(actionForStake).wrap(amount);
    }

    function _convertETHToEETH(
        address,
        address actionForStake,
        uint256 amount
    ) internal returns (uint256 resultAmount) {
        IeETH token = ILiquidityPool(actionForStake).eETH();
        resultAmount = token.balanceOf(address(this));

        ILiquidityPool(actionForStake).deposit{ value: amount }();

        resultAmount = token.balanceOf(address(this)) - resultAmount;
    }

    function _convertSTETHToEETH(
        address asset,
        address actionForStake,
        uint256 amount
    ) internal returns (uint256 resultAmount) {
        IeETH token = ILiquifier(actionForStake).liquidityPool().eETH();
        resultAmount = token.balanceOf(address(this));

        IstETH(asset).approve(actionForStake, amount);
        ILiquifier(actionForStake).depositWithERC20(asset, amount, address(0));

        resultAmount = token.balanceOf(address(this)) - resultAmount;
    }

    function _convertWSTETHToSTETH(
        address,
        address actionForStake,
        uint256 amount
    ) internal returns (uint256 resultAmount) {
        resultAmount = IwstETH(actionForStake).unwrap(amount);
    }

    // ---------------------- Convert for Unstake ----------------------
    function _convertSPETHToWEETH(
        address asset,
        address actionForUnstake,
        uint256 amount,
        address nextAsset
    ) internal returns (uint256 resultAmount) {
        IEcoERC20(asset).approve(actionForUnstake, amount);
        resultAmount = ISpectrumCoreEntry(actionForUnstake).unstake(nextAsset, address(this), amount);
    }

    function _convertWEETHToEETH(
        address asset,
        address actionForUnstake,
        uint256 amount,
        address nextAsset
    ) internal returns (uint256 resultAmount) {
        resultAmount = IweETH(actionForUnstake).unwrap(amount);
    }
}
