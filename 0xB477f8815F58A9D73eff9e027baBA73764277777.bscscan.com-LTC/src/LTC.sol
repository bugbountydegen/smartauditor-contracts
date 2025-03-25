// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "@solmate-6.8.0/src/auth/Owned.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {ERC20} from "./abstract/token/ERC20.sol";
import {ExcludedFromFeeList} from "./abstract/ExcludedFromFeeList.sol";
import {BlackList} from "./abstract/BlackList.sol";
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";
import {Timestamp, Duration} from "./utils/Types.sol";
import {BaseUSDT} from "./abstract/dex/BaseUSDT.sol";
import {_USDT, _ROUTER} from "./utils/constant.sol";
import {NFTCommunity} from "./NFTCommunity.sol";
import {Locker} from "./abstract/utils/Locker.sol";
import {IUniswapV2Router02} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router02.sol";

contract LTC is Locker, BaseUSDT, ERC20, ExcludedFromFeeList, BlackList {
    NFTCommunity public immutable nft_pool;
    string public constant name = "TFT";
    string public constant symbol = "TFT";
    Duration constant coldTime = Duration.wrap(1 minutes);

    bool public tradingSell;
    uint24 public botTime = 24 hours;
    Timestamp public tradeStartAt;
    address public treasury;

    mapping(address user => Timestamp lastTime) public lastBuyTime;

    function setTrading(uint32 timestamp) external onlyOwner {
        if (timestamp == 0) {
            tradeStartAt = Timestamp.wrap(uint32(block.timestamp));
        } else {
            tradeStartAt = Timestamp.wrap(timestamp);
        }
    }

    function setTradingSell(bool _sell) external onlyOwner {
        tradingSell = _sell;
    }

    function setBotTime(uint24 _botTime) external onlyOwner {
        botTime = _botTime;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        excludeFromFee(_treasury);
    }

    constructor() Owned(msg.sender) ERC20(18, 10_0000 ether) {
        require(_USDT < address(this), "vd");
        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
        allowance[address(this)][_ROUTER] = type(uint256).max;
        nft_pool = new NFTCommunity(msg.sender);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (inSwapAndLiquify()) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            super._transfer(sender, recipient, amount);
            lastBuyTime[recipient] = Timestamp.wrap(uint32(block.timestamp));
            return;
        }

        if (isBlackListed[sender]) {
            revert InBlackListError();
        }

        if (uniswapV2Pair == sender) {
            require(uint256(Timestamp.unwrap(tradeStartAt)) > 2, "t>2");

            lastBuyTime[recipient] = Timestamp.wrap(uint32(block.timestamp));

            if (uint256(Timestamp.unwrap(tradeStartAt)) + uint256(botTime) >= block.timestamp) {
                uint256 botfee = amount * 15 / 100;
                super._transfer(sender, treasury, botfee);
                super._transfer(sender, recipient, amount - botfee);
                return;
            }

            super._transfer(sender, recipient, amount);
        } else if (uniswapV2Pair == recipient) {
            require(tradingSell, "tradingSell");
            // sell & add liquidity
            require(
                block.timestamp >= uint256(Timestamp.unwrap(lastBuyTime[sender])) + uint256(Duration.unwrap(coldTime)),
                "cold"
            );

            uint256 burnFee = amount * 3 / 100;
            super._transfer(sender, treasury, burnFee);
            super._transfer(sender, address(this), burnFee);

            uint256 bal_this = balanceOf[address(this)];
            if (balanceOf[address(this)] >= 1000 gwei) {
                swapAndLiquify(bal_this);
            }

            super._transfer(sender, recipient, amount - (burnFee * 2));
        } else {
            // normal transfer
            lastBuyTime[recipient] = Timestamp.wrap(uint32(block.timestamp));
            super._transfer(sender, recipient, amount);
        }
    }

    function swapAndLiquify(uint256 amountIn) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_USDT);
        IUniswapV2Router02(_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // accept any amount of ETH
            path,
            address(nft_pool),
            block.timestamp
        );
    }

    function swapToNft(uint256 amountIn) external {
        require(tx.origin == msg.sender, "EOA");
        swapAndLiquify(amountIn);
    }
}
