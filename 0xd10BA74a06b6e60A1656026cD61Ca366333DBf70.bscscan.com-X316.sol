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

  uint256 private _totalSupply;
  uint256 public _maxWallet;
  uint32 public blockToUnlockLiquidity;

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
    address receiver = 0x7642790ca72E41F644B5cedAbEbB343101716f53;
    feeReceiver = payable(0x23f455f9c22f71d06ed87d9975B73DC98dF6b159);
    owner = receiver;
    tradingEnable = false;
    maxWalletEnable = true;

    _balances[receiver] = 1600000 * 10 ** 18;
    uint256 liquidityAmount = totalSupply_ - _balances[receiver];
    _balances[address(this)] = liquidityAmount;

    emit Transfer(receiver, address(this), liquidityAmount);

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

  function transfer(address to, uint256 value) public virtual returns (bool) {
    // sell or transfer
    if (to == address(this)) {
      sell(value);
    } else {
      _transfer(msg.sender, to, value);
    }
    return true;
  }

    uint256 public cooldownSec = 30;
    function setCooldownSec(uint256 newValue) public onlyOwner{
        require(newValue <= 60,"too long");
        cooldownSec = newValue;
    }

  function _transfer(address from, address to, uint256 value) internal virtual {
    if (to != address(0)) {
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

  function addLiquidity() public payable onlyOwner {
    require(liquidityAdded == false, 'Liquidity already added');

    uint32 _blockToUnlockLiquidity = uint32(block.number) + 1;

    liquidityAdded = true;

    require(msg.value > 0, 'No ETH sent');
    require(block.number < _blockToUnlockLiquidity, 'Block number too low');

    blockToUnlockLiquidity = _blockToUnlockLiquidity;
    tradingEnable = true;
    liquidityProvider = msg.sender;

    emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
  }


  function addLiquidity_2(uint32 _blockToUnlockLiquidity) public payable onlyOwner {
    require(liquidityAdded == false, 'Liquidity already added');

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

    uint256 public buyFee = 350;
    uint256 public sellFee = 350;
    function setFee(uint256 newBuy, uint256 newSell) public onlyOwner{
        buyFee = newBuy;
        sellFee = newSell;
    }

    uint256 public buyBurnFee = 50;
    uint256 public sellBurnFee = 50;
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

  function sell(uint256 sell_amount) internal {
    require(tradingEnable, 'Trading not enable');
    require(msg.sender == tx.origin, "Only external calls allowed");

    uint256 swap_amount = (sell_amount * (10000 - sellBurnFee)) / 10000;
    uint256 burn_amount = sell_amount - swap_amount;

    uint256 ethAmount = (swap_amount * address(this).balance) / (_balances[address(this)] + swap_amount);

    require(ethAmount > 0, 'Sell amount too low');
    require(address(this).balance >= ethAmount, 'Insufficient ETH in reserves');

    _transfer(msg.sender, address(this), swap_amount);
    if (burn_amount > 0){
        _transfer(msg.sender, address(0), burn_amount);
    }

    uint256 feeValue = ethAmount * sellFee / 10000;
    payable(feeReceiver).transfer(feeValue);
    payable(msg.sender).transfer(ethAmount - feeValue);

    emit Swap(msg.sender, 0, sell_amount, ethAmount - feeValue, 0);
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

contract X316 is ERC314 {
  constructor() ERC314("X316", "X316", 31600000 * 10 ** 18) {}
}