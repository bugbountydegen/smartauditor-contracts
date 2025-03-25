// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEcoERC20 } from "../../eco-libs/token/ERC20/IERC20.sol";
import { ISpectrumCoreState, SpectrumCoreState } from "./SpectrumCoreState.sol";

import { IweETH } from "../vendor/etherfi.sol";

abstract contract SpectrumCoreUtils is SpectrumCoreState {
    function _evalWEETH(address assetEvaluator, uint256 amount) internal view returns (uint256 evalValue) {
        evalValue = IweETH(assetEvaluator).getEETHByWeETH(amount);
    }

    function _getWEETHFromETH(address assetEvaluator, uint256 ethAmount) internal view returns (uint256 assetAmount) {
        assetAmount = IweETH(assetEvaluator).getWeETHByeETH(ethAmount);
    }
}
