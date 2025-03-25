/**
                                                       
                             
                                                                                          
                                                                                          
                                                 .-==+*###%%                              
                                            -+*%@@@@@@@@@@@@                              
                                        :+#@@@@@@@@@@@@@@@@@                              
                                     -*@@@@@@@@@@@@@@@@@@@@@                              
                                  :*@@@@@@@@@@@@@@@@@@@@@@@@                              
                                -#@@@@@@@@@@@@@@@@@#*+=-::..                              
                              -%@@@@@@@@@@@@@@%+-.                                        
                            .*@@@@@@@@@@@@@#-                                             
                           =@@@@@@@@@@@@#=.                                               
                          *@@@@@@@@@@@#:                                                  
                        .%@@@@@@@@@@@-               :=+*#%%                              
                        %@@@@@@@@@@*             -*%@@@@@@@@                              
                       #@@@@@@@@@@-           .*@@@@@@@@@@@@                              
                      +@@@@@@@@@@-          .*@@@@@@@@@@@@@@                              
                     :@@@@@@@@@@-          -@@@@@@@@@@@@@@@@                              
                     *@@@@@@@@@*          =@@@@@@@@@@@@%*=:.                              
                     @@@@@@@@@@          =@@@@@@@@@@%-                                    
                    :@@@@@@@@@*         :@@@@@@@@@@*                                      
                    =@@@@@@@@@-         *@@@@@@@@@#                                       
                    *@@@@@@@@@:         @@@@@@@@@@:                                       
                     .........         .@@@@@@@@@%          @@@@@@@@@@                    
                                       +@@@@@@@@@+         .@@@@@@@@@@                    
                                      -@@@@@@@@@@:         -@@@@@@@@@#                    
                                     *@@@@@@@@@@#          #@@@@@@@@@=                    
                                .:=#@@@@@@@@@@@%          :@@@@@@@@@@.                    
                              %@@@@@@@@@@@@@@@%           %@@@@@@@@@*                     
                              %@@@@@@@@@@@@@@+           #@@@@@@@@@@.                     
                              %@@@@@@@@@@@@+.           #@@@@@@@@@@:                      
                              %@@@@@@@@@*-            :%@@@@@@@@@@-                       
                              %@@@%#+-.              *@@@@@@@@@@@=                        
                                                   =@@@@@@@@@@@@:                         
                                                 =@@@@@@@@@@@@%.                          
                                             .-#@@@@@@@@@@@@@=                            
                                          :+%@@@@@@@@@@@@@@*                              
                                  .:-=+*%@@@@@@@@@@@@@@@@*:                               
                              %@@@@@@@@@@@@@@@@@@@@@@@@+                                  
                              %@@@@@@@@@@@@@@@@@@@@@#-                                    
                              %@@@@@@@@@@@@@@@@@%+:                                       
                              %@@@@@@@@@@@@@#+:                                           
                              %@@@@@%#*+=:.                                               
                              ..                                                          
                                                                                          
                                                       
ShadowGold

New money for the real world. 

Backed by real gold.

Website: ShadowGold.org
*/

//SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File: ABLE.sol


pragma solidity ^0.8.25;

interface IAggregator {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

contract ABLE is Ownable {
    address private signer;
    address private maticPair;
    address private paxgPair;
    IUniswapV2Router02 public uniswapV2Router;
    IAggregator private maticPriceFeed;
    IAggregator private paxgPriceFeed;
    IAggregator private usdcPriceFeed;

    IERC20 public sdgToken;
    IERC20 public paxgToken;
    IERC20 public wmaticToken;

    uint256 public sdgTradeBalance;
    uint256 public maticTradeBalance;
    uint256 public paxgTradeBalance;

    constructor() {
        signer = msg.sender;
        uniswapV2Router = IUniswapV2Router02(0xedf6066a2b290C185783862C7F4776A2C8077AD1);
        paxgToken = IERC20(0x553d3D295e0f695B9228246232eDF400ed3560B5);
        wmaticToken = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        maticPair = 0x580806681893D31a5b4863f157d1AC0d3d40Ff5c;
        paxgPair = 0x87da6A6e16e0A07B31AEd30C07E8FD329f8Fa44F;
        maticPriceFeed = IAggregator(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        paxgPriceFeed = IAggregator(0x0f6914d8e7e1214CDb3A4C6fbf729b75C69DF608);

        paxgToken.approve(address(uniswapV2Router), type(uint256).max);
        wmaticToken.approve(address(uniswapV2Router), type(uint256).max);
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setToken(address _sdgToken) public onlyOwner {
        sdgToken = IERC20(_sdgToken);
        sdgToken.approve(address(uniswapV2Router), type(uint256).max);
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
    
    function checkUsdPrices() public view returns (uint256 reserveMatic, uint256 reserveSdgMatic, uint256 reservePaxg, uint256 reserveSdgPaxg, uint256 maticSdgPriceInUsd, uint256 paxgSdgPriceInUsd) {
        (uint112 _reserveMatic, uint112 _reserveSdgMatic,) = IUniswapV2Pair(maticPair).getReserves();
        (uint112 _reservePaxg, uint112 _reserveSdgPaxg,) = IUniswapV2Pair(paxgPair).getReserves();

        uint256 maticPrice = uint256(maticPriceFeed.latestAnswer());
        uint256 paxgPrice = uint256(paxgPriceFeed.latestAnswer());

        uint256 scaledReserveSdgMatic = uint256(_reserveSdgMatic) * 1e9;
        uint256 scaledReserveSdgPaxg = uint256(_reserveSdgPaxg) * 1e9;

        maticSdgPriceInUsd = (_reserveMatic * maticPrice * 1e10) / scaledReserveSdgMatic;
        paxgSdgPriceInUsd = (_reservePaxg * paxgPrice * 1e10) / scaledReserveSdgPaxg;

        return (
            _reserveMatic, scaledReserveSdgMatic, 
            _reservePaxg, scaledReserveSdgPaxg, 
            maticSdgPriceInUsd, paxgSdgPriceInUsd
        );
    }

    function calculateOptimalArbitrageSpend(uint256 higherReserve, int256 percentageGap) internal pure returns (uint256 optimalSpendSdg) {
        uint256 gapProportion = uint256(abs(percentageGap)) / 2;

        optimalSpendSdg = (higherReserve * gapProportion) / 10000;

        return optimalSpendSdg;
    }

    function checkArbOpportunities(uint256 threshold) public view returns (bool opportunity, int256 percentageGap, uint256 optimalSpend, uint256 sdgBalance, uint256 maticBalance, uint256 paxgBalance) {
        (, uint256 scaledReserveSdgMatic, , uint256 scaledReserveSdgPaxg, uint256 maticSdgPriceInUsd, uint256 paxgSdgPriceInUsd) = checkUsdPrices();

        sdgBalance = sdgToken.balanceOf(address(this));
        maticBalance = address(this).balance;
        paxgBalance = paxgToken.balanceOf(address(this));

        if (maticSdgPriceInUsd == 0 || paxgSdgPriceInUsd == 0) {
            opportunity = false;
            percentageGap = 0;
            optimalSpend = 0;
        } else {
            percentageGap = ((int256(maticSdgPriceInUsd) - int256(paxgSdgPriceInUsd)) * 10000) / int256(maticSdgPriceInUsd < paxgSdgPriceInUsd ? maticSdgPriceInUsd : paxgSdgPriceInUsd);

            uint256 higherReserve;
            if (percentageGap > 0) {
                higherReserve = scaledReserveSdgMatic;
            } else {
                higherReserve = scaledReserveSdgPaxg;
            }

            optimalSpend = calculateOptimalArbitrageSpend(higherReserve, percentageGap) / 1e9;

            opportunity = uint256(abs(percentageGap)) > threshold;
        }

        return (opportunity, percentageGap, optimalSpend, sdgBalance, maticBalance, paxgBalance);
    }

    function convertTokensToDollars(uint256 amountToken, uint256 tokenPriceInUsd) public pure returns (uint256) {
        return (amountToken * tokenPriceInUsd) / 1e18;
    }

    function convertDollarsToTokens(uint256 dollarValue, uint256 tokenPriceInUsd) public pure returns (uint256) {
        return (dollarValue * 1e18) / tokenPriceInUsd;
    }

    function testView() public view returns (uint256 maticPriceInUsd, uint256 paxgPriceInUsd, uint256 maticDollars, uint256 spendAmount) {
        maticPriceInUsd = uint256(maticPriceFeed.latestAnswer()) * 1e10;
        paxgPriceInUsd = uint256(paxgPriceFeed.latestAnswer()) * 1e10;
        maticDollars = convertTokensToDollars(1000000000000000000, maticPriceInUsd);
        spendAmount = convertDollarsToTokens(maticDollars, paxgPriceInUsd);

        return (maticPriceInUsd, paxgPriceInUsd, maticDollars, spendAmount);
    }

    function swapSdgToMaticToPaxgToSdg(uint256 amountIn) external returns (int256 sdgGained) {
        require(msg.sender == signer, "Only signer wallet.");
        uint256 sdgBefore = sdgToken.balanceOf(address(this));

        uint256 maticPriceInUsd = uint256(maticPriceFeed.latestAnswer()) * 1e10;
        uint256 paxgPriceInUsd = uint256(paxgPriceFeed.latestAnswer()) * 1e10;

        uint256 maticBefore = address(this).balance;

        // Swap SDG to MATIC
        address[] memory path1 = new address[](2);
        path1[0] = address(sdgToken);
        path1[1] = address(wmaticToken);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path1,
            address(this),
            block.timestamp
        );

        uint256 maticAfter = address(this).balance - maticBefore;
        uint256 maticDollars = convertTokensToDollars(maticAfter, maticPriceInUsd);
        uint256 spendAmount = convertDollarsToTokens(maticDollars, paxgPriceInUsd);

        // Swap PAXG to SDG
        address[] memory path2 = new address[](2);
        path2[0] = address(paxgToken);
        path2[1] = address(sdgToken);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            spendAmount,
            0,
            path2,
            address(this),
            block.timestamp
        );

        if (sdgBefore < sdgToken.balanceOf(address(this))) {
            sdgGained = int256(sdgToken.balanceOf(address(this))) - int256(sdgBefore);
        } else {
            return 0;
        }
    }

    function swapSdgToPaxgToMaticToSdg(uint256 amountIn) external returns (int256 sdgGained) {
        require(msg.sender == signer, "Only signer wallet.");
        uint256 sdgBefore = sdgToken.balanceOf(address(this));

        uint256 maticPriceInUsd = uint256(maticPriceFeed.latestAnswer()) * 1e10;
        uint256 paxgPriceInUsd = uint256(paxgPriceFeed.latestAnswer()) * 1e10;

        uint256 paxgBefore = paxgToken.balanceOf(address(this));

        // Swap SDG to PAXG
        address[] memory path1 = new address[](2);
        path1[0] = address(sdgToken);
        path1[1] = address(paxgToken);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path1,
            address(this),
            block.timestamp
        );

        uint256 paxgAfter = paxgToken.balanceOf(address(this)) - paxgBefore;
        uint256 paxgDollars = convertTokensToDollars(paxgAfter, paxgPriceInUsd);
        uint256 spendAmount = convertDollarsToTokens(paxgDollars, maticPriceInUsd);


        // Swap MATIC to SDG
        address[] memory path2 = new address[](2);
        path2[0] = address(wmaticToken);
        path2[1] = address(sdgToken);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: spendAmount} (
            0,
            path2,
            address(this),
            block.timestamp
        );

        if (sdgBefore < sdgToken.balanceOf(address(this))) {
            sdgGained = int256(sdgToken.balanceOf(address(this))) - int256(sdgBefore);
        } else {
            return 0;
        }
    }

    receive() external payable {}

    function deposit(uint256 amountPaxg, uint256 amountSdg) payable public {
        if (amountPaxg > 0) {
            paxgTradeBalance += amountPaxg;
            paxgToken.transferFrom(msg.sender, address(this), amountPaxg);
        }
        if (amountSdg > 0) {
            sdgTradeBalance += amountSdg;
            sdgToken.transferFrom(msg.sender, address(this), amountSdg);
        }
        if (msg.value > 0) {
            maticTradeBalance += msg.value;
        }
    }

    function getSdgGained() public view returns (uint256) {
            return sdgToken.balanceOf(address(this));
    }

    function withdrawSdgGains() external onlyOwner {
            sdgToken.transfer(owner(), sdgToken.balanceOf(address(this)));
    }

    function withdrawFromMaticTradeBalance(uint256 amount) external onlyOwner {
        if (amount > maticTradeBalance) {
            payable(owner()).transfer(amount);
            maticTradeBalance = 0;
        } else {
            payable(owner()).transfer(amount);
            maticTradeBalance -= amount;
        }
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }
}