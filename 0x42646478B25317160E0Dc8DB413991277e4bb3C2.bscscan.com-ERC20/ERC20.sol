// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./draft-IERC6093.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

interface ILPPledge {
    function updataReward(uint256 amount) external;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors, Ownable , ReentrancyGuard{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, address initialOwner) Ownable(initialOwner) {
        _name = name_;
        _symbol = symbol_;
        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        usdtPair = swapFactory.createPair(address(this), USDT);
        isPairAddr[usdtPair] = true;
        _whiteList[address(0)] = true;
        _whiteList[0x5B55eB22439b68797a12a62dfB5a5C30A7c9f5a9] = true;
        _whiteList[address(this)] = true;
        _mint(0x5B55eB22439b68797a12a62dfB5a5C30A7c9f5a9,10000000000 * 10 ** 18);
        _invitor[0x03f4Cafa54B85B804F72aeC7d014F71D52758052] = address(1);
        _allowances[address(this)][address(_swapRouter)] = type(uint256).max;
        startTime = 1730350800;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `requestedDecrease`.
     */
    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        if(!isPairAddr[from]) {
            updateUserEarn(from);
        } else {
            uint256 price = getSwapRouterAmountsOut(1e18);
            uint256 buyValue = price * amount / 1e18;
            if(buyValue > buyMaxValue) {
                revert("buyMaxAmount");
            }
            uint256 culDays = (block.timestamp - startTime) / earnInterval;
            uint256 value = networkDayBuyValue[culDays];
            if(value + buyValue > tolDayBuyMaxValue) {
                revert("tolDayBuyMaxValue");
            }
            networkDayBuyValue[culDays] += buyValue;
        }
        if(!isPairAddr[to]) {
            updateUserEarn(to);
        }
        _update(from, to, amount);
        if(amount > 0){
            register(from,to);
        }
    }

    /**
     * @dev Transfers `amount` of tokens from `from` to `to`, or alternatively mints (or burns) if `from` (or `to`) is
     * the zero address. All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < amount) {
                revert ERC20InsufficientBalance(from, fromBalance, amount);
            }
            unchecked {
                // Overflow not possible: amount <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - amount;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: amount <= totalSupply or amount <= fromBalance <= totalSupply.
                _totalSupply -= amount;
            }
        } else {
            if(!_whiteList[from] && !_whiteList[to]) {
                uint256 feeA = amount * transferFee / 10000;
                unchecked {
                    _balances[transferFeeAddr] += feeA;
                }
                _LPPledge.updataReward(feeA);

                emit Transfer(from, transferFeeAddr, feeA);

                uint256 sellFeeA;
                uint256 burnA;
                if(isPairAddr[to]) {
                    sellToken();

                    sellFeeA = amount * sellFee / 10000;
                    burnA = amount * sellBurnFee / 10000;

                    unchecked {
                        _balances[address(this)] += sellFeeA;
                        _balances[sellBurnFeeAddr] += burnA;
                        
                    }                   
                    emit Transfer(from, address(this), sellFeeA);
                    emit Transfer(from, sellBurnFeeAddr, burnA);                           
                }
                amount = amount - feeA - sellFeeA - burnA;
            }
            unchecked {
                // Overflow not possible: balance + amount is at most totalSupply, which we know fits into a uint256.
                _balances[to] += amount;
            }
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, by transferring it to address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    ISwapRouter public constant _swapRouter= ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    ILPPledge public _LPPledge;
    address public usdtPair;
    mapping(address => bool) public isPairAddr;
    mapping(address => address) private _invitor;
    mapping(address => uint256) private _invitorNum;
    mapping(address => uint256) public validInvitorNum;
    mapping(address => address[]) private _directThrust;
    mapping(address => uint256) private userInvitorEarn;
    mapping(address => bool) private _whiteList;
    mapping(address => uint256) public userEarn;
    mapping(address => uint256) public lastUpdateTime;
    mapping(uint256 => uint256) public networkDayBuyValue;
    mapping(address => UserEarnInfo) public userEarnInfos;


    uint256 public startTime;
    uint256 public buyMaxValue = 100e18;
    uint256 public tolDayBuyMaxValue = 20000e18;
    uint256 public earnInterval = 24 hours;
    uint256 public transferFee = 500;
    uint256 public sellFee = 1000;
    uint256 public sellBurnFee = 1000;
    uint256 public sellFeeSwapAmount = 100e18;
    address public transferFeeAddr;
    address public sellFeeAddrs = 0x13224355855a197E9472aA95DEe84417622553C7;
    address public sellBurnFeeAddr = 0x000000000000000000000000000000000000dEaD;
    bool public isSellFeeSwaping;

    uint256[20] public invitorEarnScale = [2000,1800,1600,1100,400,300,200,200,200,200,200,200,200,200,200,200,200,200,200,200];
    uint256[4] public usdtValue = [1,300e18,400e18,500e18];
    uint256[4] public usdtEarn = [50,100,300,500];

    struct UserEarnInfo {
        uint256 tolEarn;
        uint256 tolInvitorEarn;
    }

    event Register(address indexed account, address indexed referRecommender, uint256 usdtValue, uint256 time);
    event UpdateUserEarn(address indexed user,uint256 earnToken,uint256 elapsedCount,uint256 price, uint256 userBalances);
    event UpdateInvitorEarn(address indexed account, address indexed referRecommender, uint256 tier, uint256 invitorEarn);
    event SetWhite(address addr, bool enable);
    event SetWhites(address[] addrs, bool enable);

    function withdraw() external nonReentrant {
        address user = _msgSender();
        _withdraw(user);
    }

    function _withdraw(address _user) internal {
        updateUserEarn(_user);
        uint256 earn = userEarn[_user];
        uint256 invitorEarn = userInvitorEarn[_user];
        if(earn > 0) {
            userEarn[_user] = 0;
            _update(usdtPair, _user, earn);
            userEarnInfos[_user].tolEarn += earn;
        }
        if(invitorEarn > 0) {
            userInvitorEarn[_user] = 0;
            _update(usdtPair, _user, invitorEarn);
            userEarnInfos[_user].tolInvitorEarn += invitorEarn;
        }
        IUniswapV2Pair iPair = IUniswapV2Pair(usdtPair);
        iPair.sync();

    }

    function register(address from, address to) private {
        if(!isPairAddr[from] && !isPairAddr[to]){
            if(_invitor[from] == address(0) && _invitor[to] != address(0)) {
                _invitor[from] = to;
                _invitorNum[to] ++;
                _directThrust[to].push(from);
                uint256 price = getSwapRouterAmountsOut(1e18);
                uint256 usdtV = _balances[from] * price / 1e18;
                if(usdtV >= usdtValue[1]) {
                    validInvitorNum[to] ++;
                }
                emit Register(from, to, usdtV, block.timestamp);
            }
        } 
    }

    function updateUserEarn(address user) private {
        if(lastUpdateTime[user] == 0) {
            lastUpdateTime[user] = block.timestamp;
        }
        uint256 elapsedTime = block.timestamp - lastUpdateTime[user];
        uint256 elapsedCount = elapsedTime / earnInterval;
        if(elapsedCount > 0) {
            lastUpdateTime[user] += elapsedCount * earnInterval;
            uint256 price = getSwapRouterAmountsOut(1e18);
            uint256 earnToken = calcEarn(elapsedCount,_balances[user],price);
            userEarn[user] += earnToken;
            updateInvitorEarn(user,earnToken);

            emit UpdateUserEarn(user,earnToken,elapsedCount,price,_balances[user]);
        }
    }

    function calcEarn(uint256 elapsedCount, uint256 balance, uint256 price) private view returns (uint256) {
        uint256 usdtV = balance * price / 1e18;
        if(usdtV < usdtValue[0]) {
            uint256 earn = usdtV * usdtEarn[0] * elapsedCount / 10000;
            return earn * 1e18 / price;
        }
        for(uint256 i = usdtValue.length; i != 0; i--) {
            if(usdtValue[i-1] <= usdtV) {
                if(i == usdtValue.length) {
                    uint256 earn = usdtValue[i-1] * usdtEarn[i-1] * elapsedCount / 10000;
                    return earn * 1e18 / price;
                } else {
                    uint256 earn = usdtV * usdtEarn[i-1] * elapsedCount / 10000;
                    return earn * 1e18 / price;
                }               
            }    
        }
        return 0;
    }

    function updateInvitorEarn(address user,uint256 amount) private {
        address addr = _invitor[user];
        uint256 price = getSwapRouterAmountsOut(1e18);
        uint256 usdtV;
        for(uint256 i = 0;i < 20 && addr != address(0); i++) {
            usdtV = _balances[addr] * price / 1e18;
            // invitor usdt value must be min usdt
            if(validInvitorNum[addr] > i && usdtV >= usdtValue[1]) {
                uint256 invitorEarn = amount * invitorEarnScale[i] / 10000;
                userInvitorEarn[addr] += invitorEarn;
                emit UpdateInvitorEarn(user,addr,i,invitorEarn);
            }
            addr = _invitor[addr];
        }
    }

    function sellToken() private {
        if(!isSellFeeSwaping && _balances[address(this)] >= sellFeeSwapAmount) {
            isSellFeeSwaping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = address(USDT);  
            swapTokensForTokens(path,_balances[address(this)],0,sellFeeAddrs);
            isSellFeeSwaping = false;
        }
    }

    function getSwapRouterAmountsOut(uint256 _amount) private view returns (uint256) {
        uint256 amountOut;
        address[] memory path = new address[](2);
        path[0] =  address(this);
        path[1] = USDT;
        uint256[] memory amounts = _swapRouter.getAmountsOut(_amount, path);
        amountOut = amounts[1];
        return amountOut;
    }

    function swapTokensForTokens(address[] memory path, uint256 tokenAmount,uint256 tokenOutMin, address to) private {
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            tokenOutMin, 
            path,
            to,
            block.timestamp + 60
        );
    }

    function getTokenPrice() external view returns(uint256) {
        return getSwapRouterAmountsOut(1e18);
    }

    function getBuyMaxAmount() external view returns(uint256) {
        return buyMaxValue * 1e18 / getSwapRouterAmountsOut(1e18);
    }

    function getUserInvitorEarn(address user) external view returns(uint256) {
        return userInvitorEarn[user];
    }

    function getUserInvitor(address user) external view returns(address) {
        return _invitor[user];
    }

    function getUserInvitorNum(address user) external view returns(uint256) {
        return _invitorNum[user];
    }

    receive() external payable {
        _withdraw(_msgSender());
    }
    
    function isWhite(address addr) external view returns(bool) {
       return _whiteList[addr];
    }

    function setWhite(address addr, bool enable) external onlyOwner {
        _whiteList[addr] = enable;
        emit SetWhite(addr,enable);
    }

    function setWhites(address[] memory addrs, bool enable) external onlyOwner {
        for(uint256 i = 0; i < addrs.length; i++) {
            _whiteList[addrs[i]] = enable;
            emit SetWhites(addrs,enable);
        }
    } 

    function setBuyValue(uint256 buyMaxValue_,uint256 tolDayBuyMaxValue_) external onlyOwner {
        buyMaxValue = buyMaxValue_;
        tolDayBuyMaxValue = tolDayBuyMaxValue_;
    }

    function setEarnInterval(uint256 earnInterval_,uint256 startTime_) external onlyOwner {
        earnInterval = earnInterval_;
        startTime = startTime_;
    }

    function setTransferFeeAddr(address transferFeeAddr_) external onlyOwner {
        transferFeeAddr = transferFeeAddr_;
        _LPPledge= ILPPledge(transferFeeAddr_);
    }

    function setSellFeeAddrs_(address sellFeeAddrs_) external onlyOwner {
        sellFeeAddrs = sellFeeAddrs_;
    }

    function setSellFeeSwapAmount_(uint256 sellFeeSwapAmount_) external onlyOwner {
        sellFeeSwapAmount = sellFeeSwapAmount_;
    }

    function setUsdtEarn(uint256 usdtEarn0, uint256 usdtEarn1, uint256 usdtEarn2, uint256 usdtEarn3) external onlyOwner {
        usdtEarn[0] = usdtEarn0;
        usdtEarn[1]= usdtEarn1;
        usdtEarn[2] = usdtEarn2;
        usdtEarn[3] = usdtEarn3;
    }

    function setUsdtValue(uint256 usdtValue0, uint256 usdtValue1, uint256 usdtValue2, uint256 usdtValue3) external onlyOwner {
        usdtValue[0] = usdtValue0;
        usdtValue[1]= usdtValue1;
        usdtValue[2] = usdtValue2;
        usdtValue[3] = usdtValue3;
    }
    
}