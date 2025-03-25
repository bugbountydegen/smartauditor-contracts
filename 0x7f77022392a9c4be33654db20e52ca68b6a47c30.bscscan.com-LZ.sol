pragma solidity ^0.8.1;
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface ISwapPair {
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function sync() external;
}
interface ISwapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _totalCirculation;
    uint256 private _minTotalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function totalCirculation() public view virtual returns (uint256) {
        return _totalCirculation;
    }
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _totalCirculation += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount)
        internal
        virtual
        returns (bool)
    {
        require(account != address(0), "ERC20: burn from the zero address");
        if (_totalCirculation > _minTotalSupply + amount) {
            _beforeTokenTransfer(account, address(0), amount);
            uint256 accountBalance = _balances[account];
            require(
                accountBalance >= amount,
                "ERC20: burn amount exceeds balance"
            );
            unchecked {
                _balances[account] = accountBalance - amount;
                _balances[address(0)] += amount;
            }
            _totalCirculation -= amount;
            emit Transfer(account, address(0), amount);
            _afterTokenTransfer(account, address(0), amount);
            return true;
        }
        return false;
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function setMinTotalSupply(uint256 amount) internal virtual {
        _minTotalSupply = amount;
    }
}
contract Refer {
    mapping(address => address) private _refers;
    mapping(address => address[]) private _referees;
    event ReferSet(address _refer, address _referee);
    function hasRefer(address account) public view returns (bool) {
        return _refers[account] != address(0);
    }
    function getRefer(address account) public view returns (address) {
        return _refers[account];
    }
    function refereesCount(address account) public view returns (uint256) {
        return _referees[account].length;
    }
    function referees(address account, uint256 index)
        public
        view
        returns (address)
    {
        return _referees[account][index];
    }
    function _setRefer(address _refer, address _referee) internal {
        _beforeSetRefer(_refer, _referee);
        _refers[_referee] = _refer;
        _referees[_refer].push(_referee);
        emit ReferSet(_refer, _referee);
    }
    function _beforeSetRefer(address _refer, address _referee)
        internal
        view
        virtual
    {
        require(_refer != address(0), "Refer: Can not set to 0");
        require(_refer != _referee, "Refer: Can not set to self");
        require(getRefer(_referee) == address(0), "Refer: Already has a refer");
        require(refereesCount(_referee) == 0, "Refer: Already has referees");
    }
}
contract LZ is ERC20, Ownable, Refer {
    using Address for address;
    mapping(address => bool) public isBlackList;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isSwapPair;
    mapping(address => bool) public isSwapExempt;
    bool public isSwap;
    bool public isConcise;
    address private _nft;
    address public manager;
    IERC20 private _USDT;
    address private _swapPair;
    ISwapRouter private _swapRouter;
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function withdrawToken(IERC20 token, uint256 amount) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            token.transfer(msg.sender, amount);
        }
    }
    function withdrawThis() public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            super._transfer(
                address(this),
                msg.sender,
                balanceOf(address(this))
            );
        }
    }
    function setManager(address account) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            manager = account;
        }
    }
    function setNFT(address nft) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            _nft = nft;
        }
    }
    function setConcise(bool newVal) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            isConcise = newVal;
        }
    }
    function setIsFeeExempt(address account, bool newValue) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            isFeeExempt[account] = newValue;
        }
    }
    function setIsBlackList(address account, bool newValue) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            isBlackList[account] = newValue;
        }
    }
    function setIsSwapExempt(address account, bool newValue) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            isSwapExempt[account] = newValue;
        }
    }
    function setIsSwap(bool swap) public {
        if (owner() == _msgSender() || manager == _msgSender()) {
            isSwap = swap;
        }
    }
    constructor() ERC20("LZ", "LZ") {
        _nft = 0xd36Fd658238d83D554916B753622e7812AC8B268;
        manager = 0xE487F8907732990ACfd735e51B20e40927e2C971;
        address admin = 0x22d6cE5043D9E00e8a684b984Aaae84906b9a47D;
        _USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        _swapRouter = ISwapRouter(routerAddress);
        _swapPair = ISwapFactory(_swapRouter.factory()).createPair(
            address(this),
            address(_USDT)
        );
        isSwapPair[_swapPair] = true;
        isSwapExempt[address(this)] = true;
        isSwapExempt[admin] = true;
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[admin] = true;
        _mint(admin, 200_0000 * 10**decimals());
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBlackList[from], "ERC20: you are in black list");
        if (isConcise) {
            super._transfer(from, to, amount);
        } else if (isSwapPair[from] || isSwapPair[to]) {
            if (isSwapPair[to])
                require(isSwap || isSwapExempt[from], "No Swap");
            if (isSwapPair[from])
                require(isSwap || isSwapExempt[to], "No Swap");
            if (isSwapPair[to] && from != address(this)) {
                require(amount <= (balanceOf(from) * 99) / 100, "Not All");
            }
            if (isFeeExempt[from] || isFeeExempt[to]) {
                super._transfer(from, to, amount);
            } else {
                uint256 every = amount / 100;
                uint256 amountFainel = amount - every * 6;
                super._transfer(from, address(this), every);
                super._transfer(from, _nft, every * 2);
                uint256 burnAmount = every;
                address refer = !isSwapPair[from] ? from : to;
                if (hasRefer(refer)) {
                    refer = getRefer(refer);
                    super._transfer(from, refer, every);
                    if (hasRefer(refer)) {
                        refer = getRefer(refer);
                        super._transfer(from, refer, every);
                    } else {
                        burnAmount += every;
                    }
                } else {
                    burnAmount += every * 2;
                }
                if (!super._burn(from, burnAmount)) {
                    amountFainel += burnAmount;
                }
                super._transfer(from, to, amountFainel);
            }
        } else {
            if (from != address(this)) {
                require(amount <= (balanceOf(from) * 99) / 100, "Not All");
            }
            if (isFeeExempt[from] || isFeeExempt[to]) {
                super._transfer(from, to, amount);
            } else {
                uint256 every = amount / 100;
                if (super._burn(from, every)) {
                    super._transfer(from, to, amount - every);
                } else {
                    super._transfer(from, to, amount);
                }
            }
            if (
                (!hasRefer(to)) &&
                (from != to) &&
                (from != address(0)) &&
                (to != address(0)) &&
                refereesCount(to) == 0
            ) {
                _setRefer(from, to);
            }
            if (balanceOf(address(this)) > 0) {
                super._transfer(
                    address(this),
                    _swapPair,
                    balanceOf(address(this))
                );
                ISwapPair(_swapPair).sync();
            }
        }
    }
}