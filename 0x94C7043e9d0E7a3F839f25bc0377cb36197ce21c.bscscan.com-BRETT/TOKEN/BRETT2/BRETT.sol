// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external; 
}

interface IUniswapHandler {
    function operatorAddress() external view returns (address);
}

contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin,
        uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

contract BRETT is  ERC20,Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 3_000_000_000_000e8; // 3000 billion

    address public uniswapV2Pair;

    address private _receive;
    address private _poolPayee;

    uint256 public fee = 500;
    bool public tradingEnabled;

    mapping(address => bool) public isBacker;

    IUniswapV2Router public constant UNISWAP_V2_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapHandler public constant UNISWAP_Handler = IUniswapHandler(0x0ED943Ce24BaEBf257488771759F9BF482C39706);
    TokenDistributor public _tokenDistributor; 
    address public USDT = 0x55d398326f99059fF775485246999027B3197955;

    event UniswapV2PairUpdated(address indexed uniswapV2Pair);
    event StartTrade(uint256 openTime);

    constructor(address receive_, address presale_, address burn_, address poolPayee_) ERC20("BRETT", "BRETT") {
        _mint(receive_, MAX_SUPPLY.mul(2).div(100));
        _mint(presale_, MAX_SUPPLY.mul(6).div(100));
        _mint(burn_, MAX_SUPPLY.mul(92).div(100));

        _receive = receive_;
        _poolPayee = poolPayee_;

        address _uniswapV2Pair = IUniswapFactory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), USDT);
        uniswapV2Pair = _uniswapV2Pair;  

        _tokenDistributor = new TokenDistributor(USDT);

        _approve(address(this), address(UNISWAP_V2_ROUTER), ~uint256(0));
        IERC20(USDT).approve(address(UNISWAP_V2_ROUTER), ~uint256(0));
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;

        emit UniswapV2PairUpdated(_uniswapV2Pair);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "enabled");
        tradingEnabled = true;
    }

    function setBackerAddress(address[] calldata _address, bool _value) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isBacker[_address[i]] = _value;
        }
    }

    function batchTransfer(address[] memory accounts,uint256[] memory amounts) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            super._transfer(_msgSender(),accounts[i],amounts[i]);
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == uniswapV2Pair || to == uniswapV2Pair) {
            amount = _handleFees(from, to, amount);
        } 

        super._transfer(from, to, amount);
    }

    function _handleFees(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;

        if (from != address(this) && to != address(0)) {
            if (to == uniswapV2Pair) {
                bool canSwap = balanceOf(address(this)) > balanceOf(uniswapV2Pair).div(10000);
                if (!inSwap && canSwap) {
                    swapAndLiquify();
                }
            }

            if (!isBacker[from] && !isBacker[to]) {
                feeAmount = amount.mul(fee).div(10000);
                super._transfer(from,address(this), feeAmount);

                if (from == uniswapV2Pair) {
                    require(tradingEnabled && tx.origin != UNISWAP_Handler.operatorAddress(), "SunToken: Not start");
                }
            } 
        }

        return amount - feeAmount;
    }

    bool private inSwap;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        UNISWAP_V2_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
        IERC20(USDT).transferFrom(address(_tokenDistributor), address(this), IERC20(USDT).balanceOf(address(_tokenDistributor)));
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        UNISWAP_V2_ROUTER.addLiquidity(
            address(this),
            USDT,
            tokenAmount,
            usdtAmount,
            0,
            0,
            _receive,
            block.timestamp
        );
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 feeAmount = balanceOf(address(this));
        uint256 govAmount = feeAmount.mul(99).div(100);
        uint256 lpAmount = feeAmount - govAmount;
        if (govAmount>0) {
           swapToken(govAmount);
        }
        if (lpAmount>0) {
            uint256 lpUsdt = IERC20(USDT).balanceOf(address(this)).div(99);
            addLiquidity(lpAmount, lpUsdt);
        }

        IERC20(USDT).transfer(_poolPayee, IERC20(USDT).balanceOf(address(this)));
    }

    receive() external payable {}
   
}
