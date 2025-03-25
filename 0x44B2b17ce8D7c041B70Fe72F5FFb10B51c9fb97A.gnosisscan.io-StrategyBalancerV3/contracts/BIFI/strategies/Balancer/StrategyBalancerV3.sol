// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseAllToNativeFactoryStrat } from "../Common/BaseAllToNativeFactoryStrat.sol";
import { IBeefySwapper } from "../../interfaces/beefy/IBeefySwapper.sol";
import { IRewardsGauge } from "../../interfaces/curve/IRewardsGauge.sol";
import { IAuraRewardPool } from "../../interfaces/aura/IAuraRewardPool.sol";
import { IAuraBooster } from "../../interfaces/aura/IAuraBooster.sol";
import { IBalancerVaultV3 } from "../../interfaces/beethovenx/IBalancerVaultV3.sol";
import { SafeERC20, IERC20 } from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBalancerPool {
    function getTokens() external view returns (address[] memory tokens);
}

interface IPermit2 {
    function approve(address token, address spender, uint160 amount, uint48 deadline) external;
}

interface IMinter {
    function mint(address gauge) external;
}

// Strategy for Balancer/Aura for Balancer V3
contract StrategyBalancerV3 is BaseAllToNativeFactoryStrat {
    using SafeERC20 for IERC20;

    uint256 private constant NOT_AURA = 1234567;
    bool private useAura;

    IRewardsGauge public gauge;
    IAuraBooster public booster;
    address public rewardPool;
    IMinter public minter;
    IBalancerVaultV3 public balancerVault;
    uint256 public pid;

    uint256 private depositTokenIndex;
    uint256 private tokensLength;

    bool private addingLiquidity;

    error OnlyBalancerVault();
    error AddingLiquidityNotAllowed();

    function initialize(
        address _gauge,
        address _booster,
        address _balancerVault,
        uint256 _pid,
        address[] calldata _rewards,
        Addresses calldata _commonAddresses
    ) public initializer {
        gauge = IRewardsGauge(_gauge);
        balancerVault = IBalancerVaultV3(_balancerVault);
        booster = IAuraBooster(_booster);
        pid = _pid;
        if (pid != NOT_AURA) useAura = true;

        if (useAura) (,,,rewardPool,,) = booster.poolInfo(pid);
        if (!useAura) minter = IMinter(gauge.bal_pseudo_minter());

        __BaseStrategy_init(_commonAddresses, _rewards);

         address[] memory tokens = IBalancerPool(want).getTokens();
        tokensLength = tokens.length;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == depositToken) {
                depositTokenIndex = i;
                break;
            }
        }
        _giveAllowances();
    }

    function balanceOfPool() public view override returns (uint bal) {
        if (useAura) return IAuraRewardPool(rewardPool).balanceOf(address(this));
        else return gauge.balanceOf(address(this));
    }

    function stratName() public pure override returns (string memory) {
        return "BalancerV3";
    }

    function _deposit(uint _amount) internal override {
        if (_amount > 0) {
            if (useAura) booster.deposit(pid, _amount, true);
            else gauge.deposit(_amount);
        } 
    }

    function _withdraw(uint _amount) internal override {
        if (_amount > 0) {
            if (useAura) IAuraRewardPool(rewardPool).withdrawAndUnwrap(_amount, false);
            else gauge.withdraw(_amount);
        }
    }

    function _emergencyWithdraw() internal override {
        _withdraw(balanceOfPool());
    }

    function _claim() internal override {
        if (useAura) IAuraRewardPool(rewardPool).getReward();
        else {
            if (address(minter) != address(0)) minter.mint(address(this));
            gauge.claim_rewards(address(this));
        }
    }

    function _swapNativeToWant() internal override {
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (depositToken != native) IBeefySwapper(swapper).swap(native, depositToken, nativeBal);

        if (depositToken != want) {
            uint256 depositBal = IERC20(depositToken).balanceOf(address(this));

            addingLiquidity = true;
            balancerVault.unlock(abi.encodeCall(this.balancerJoin, (depositBal)));
        }
    }

    function _giveAllowances() internal {
        uint max = type(uint).max;

        if (useAura) _approve(want, address(booster), max);
        else _approve(want, address(gauge), max);
        _approve(native, address(swapper), max);
    }

    function _removeAllowances() internal {
        if (useAura) _approve(want, address(booster), 0);
        else _approve(want, address(gauge), 0);
        _approve(native, address(swapper), 0);
    }

    function panic() public override onlyManager {
        pause();
        _emergencyWithdraw();
        _removeAllowances();
    }

    function pause() public override onlyManager {
        _pause();
        _removeAllowances();
    }

    function unpause() external override onlyManager {
        _unpause();
        _giveAllowances();
        deposit();
    }

    function setPid(uint256 _pid, address _gauge, address _booster) external onlyOwner {
        _emergencyWithdraw();
        _removeAllowances();
        pid = _pid;
        if (pid == NOT_AURA) gauge = IRewardsGauge(_gauge);
        else (,,,rewardPool,,) = booster.poolInfo(pid);
        if (_booster != address(0)) booster = IAuraBooster(_booster);
        _giveAllowances();
        deposit();
    }


    function _approve(address _token, address _spender, uint amount) internal {
        IERC20(_token).approve(_spender, amount);
    }

    function balancerJoin(uint256 _amountIn) external returns (uint256 bptAmountOut) {
        if (msg.sender != address(balancerVault)) revert OnlyBalancerVault();
        if (!addingLiquidity) revert AddingLiquidityNotAllowed();

        uint256[] memory amounts = new uint256[](tokensLength);
        amounts[depositTokenIndex] = _amountIn;

        IERC20(depositToken).safeTransfer(address(balancerVault), _amountIn);
        balancerVault.settle(depositToken, _amountIn);
       (, bptAmountOut,) = balancerVault.addLiquidity(IBalancerVaultV3.AddLiquidityParams({
            pool: want,
            to: address(this),
            maxAmountsIn: amounts,
            minBptAmountOut: 0,
            kind: IBalancerVaultV3.AddLiquidityKind.UNBALANCED,
            userData: ""
        }));

        addingLiquidity = false;
    }

    function _verifyRewardToken(address token) internal view override {}
}
