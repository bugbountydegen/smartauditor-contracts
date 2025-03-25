// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface DividendPayingTokenOptionalInterface {
    function setBalance(address account, uint256 newBalance) external ;
}
interface IEERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );
}

abstract contract ERC314 is IEERC314 {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastTxTime;
    mapping(address => uint32) private lastTransaction;
    mapping (address => uint256) public burnAmount;

    uint256 private _totalSupply;
    uint256 public blockToUnlockLiquidity;
    uint256 public mintBNB;
    uint256 public feeTimes;

    string private _name;
    string private _symbol;

    mapping(address => mapping(address => uint256)) private _allowances;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address public owner;
    address public liquidityProvider;
    uint256 public startBlock;
    uint256 public mintStartTime;
   
    uint256 public _destoryFee;


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

    function tradingEnable() public view returns (bool) {
        return block.number >= startBlock && startBlock != 0;
    }
    
    function mintEnable() public view returns (bool) {
        return block.timestamp >= mintStartTime && mintStartTime != 0;
    }

    address payable public _destoryDivd;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;

        address receiver = msg.sender;
        _destoryDivd = payable(0xfd141F1e1B1CBBAC345e0E83849356e5f5D66666);
        owner = receiver;

        _destoryFee=300;
        blockToUnlockLiquidity = block.number;
        liquidityProvider = receiver;

        mintBNB=20 ether;
        feeTimes=3;
        uint256 airdrop=totalSupply_/10;
        _balances[receiver] = airdrop;
        emit Transfer(address(0), receiver, airdrop);
        _balances[address(this)] = totalSupply_-airdrop;
        emit Transfer(address(0), address(this), totalSupply_-airdrop);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function setFeeReceiver(address destoryDivd)public onlyLiquidityProvider {
        _destoryDivd=payable(destoryDivd);
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(msg.sender, value);
        } else {
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }

    function allowance(address _owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        address _owner = msg.sender;
        _approve(_owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);

        if (to == address(this)) {
            sell(from, amount);
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {

        if (to == address(this)) {
            require(
                lastTransaction[msg.sender] != block.number,
                "You can't make two transactions in the same block"
            );
            lastTransaction[msg.sender] = uint32(block.number);

            require(
                block.timestamp >= _lastTxTime[msg.sender] + 10,
                "Sender must wait for cooldown"
            );
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

    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    function removeLiquidity() public onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        startBlock = 0;

        payable(msg.sender).transfer(address(this).balance);
    }

    function extendLiquidityLock(uint32 _blockToUnlockLiquidity)
        public
        onlyLiquidityProvider
    {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    function start(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function startMint(uint256 _startTime ) public onlyOwner{
        mintStartTime= _startTime;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
    function transferliquidityProvider(address newOwner) public virtual onlyLiquidityProvider {
        require(newOwner != address(0), "liquidityProvider: new owner is the zero address");
        liquidityProvider = newOwner;
    }
    function setFee(uint256 destoryFee,uint256 timesfee) public onlyLiquidityProvider {
        _destoryFee=destoryFee;
        feeTimes=timesfee;
    }

    function getAmountOut(uint256 value, bool _buy)
        public
        view
        returns (uint256)
    {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    function buy(uint256 swapValue ,uint256 burn_fee) internal {
        require(tradingEnable(), "Trading not enable");

        uint256 token_amount = ((swapValue+burn_fee) * _balances[address(this)]) /
            (address(this).balance);
        uint256  burn_amount=burn_fee*token_amount/(swapValue+burn_fee);
        token_amount-=burn_amount;
        address from=msg.sender;
        _transfer(address(this), from, token_amount);
        burnAmount[from] +=swapValue*feeTimes;
        DividendPayingTokenOptionalInterface (_destoryDivd).setBalance(from, burnAmount[from]);
        _transfer(address(this), address(0xdead), burn_amount);

        emit Swap(msg.sender, swapValue, 0, 0, token_amount);

    }

    function sell(address _owner, uint256 sell_amount) internal {
        require(tradingEnable(), "Trading not enable");
        uint256 burn_amount = sell_amount * _destoryFee /10000;
        uint256 swap_amount = sell_amount-burn_amount;

        uint256 ethAmount = (swap_amount * address(this).balance) /
            (_balances[address(this)] + swap_amount);

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );

        _transfer(_owner, address(this), swap_amount-burn_amount);
        _transfer(msg.sender, address(0xdead), burn_amount);

        payable(_owner).transfer(ethAmount);
        

        emit Swap(_owner, 0, sell_amount, ethAmount , 0);
    }

    function senddivid(uint256 value) internal {

        (bool sucess,)=_destoryDivd.call{value:value}(
                new bytes(0)
            );

        require(sucess ,"senddivid Fail");
    }
    function mint(uint256 msgValue )internal  {
        require(mintEnable(),"!mint no start");
        address account = msg.sender;
        require(((msgValue>=0.1 ether && msgValue<= 0.5 ether) || account==owner) && burnAmount[account]==0);
        uint256 balance=address(this).balance;
        if(balance<=mintBNB){ 
            uint256 DestoryAmount=totalSupply()*msgValue/mintBNB/2;
            _transfer(address(this), address(0xdead), DestoryAmount);
            burnAmount[account]=msgValue*feeTimes;
            DividendPayingTokenOptionalInterface (_destoryDivd).setBalance(account, burnAmount[account]);
        }else{
            uint256 remainderValue=balance-mintBNB;
            msgValue=msgValue-remainderValue;
            uint256 DestoryAmount=totalSupply()*msgValue/mintBNB/2;
            _transfer(address(this), address(0xdead), DestoryAmount);
            burnAmount[account]=msgValue*feeTimes;
            DividendPayingTokenOptionalInterface (_destoryDivd).setBalance(account, burnAmount[account]);
            startBlock=block.number;
            buyFun(remainderValue);
        } 
    }
    receive() external payable {
        address account = msg.sender;
        uint256 msgValue = msg.value;
        if (account != tx.origin) {
            return;
        }
        if (!tradingEnable()) {
            mint(msgValue);
            return ;
        }
        buyFun(msg.value);
    }
    function buyFun(uint256 msgValue) internal {
        uint256 feeValueToDead = (msgValue * _destoryFee) / 10000;
        uint256 swapValue = (msgValue - feeValueToDead)/2;
        buy(swapValue,feeValueToDead);
        senddivid(msgValue-swapValue-feeValueToDead);
    }

}

contract BNBvip is ERC314 {
    constructor() ERC314("SUPER VIP", "SUPER VIP", 66666666 * 10**18) {}
}