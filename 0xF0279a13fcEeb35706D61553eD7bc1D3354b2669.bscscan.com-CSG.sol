// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICP {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed from, address indexed to, uint256 value);
  event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
  event RemoveLiquidity(uint256 value);
  event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out);
  event FairMinted(address indexed to, uint256 amount, uint256 ethAmount);
  event FairLaunch(address indexed to, uint256 amount, uint256 ethAmount);
  event Burn(address indexed to, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}

abstract contract ChangeProtocol is ICP {
    using SafeMath for uint256;
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public _minWallet;
    uint32 public blockToUnlockLiquidity;

    string private _name;
    string private _symbol;

    address public owner;
    address public liquidityProvider;
 
    address public feePoolAddress;

    bool public presaleEnable;
    bool public publicPresale;
    bool public tradingEnable;
    bool public liquidityAdded;

    uint256 public presaleAmount;
    uint256 public liquidityAmount;

    mapping(address => uint256) public preSaleCount;
    mapping(address account => uint32) private lastTransaction;
    mapping(address => bool) public includeAccount;
    mapping(address => uint256) public canPreSaleNum;
    mapping(address => bool) public txAgent;
    uint256 public preSaleTokenUnitAmount;
    uint256 public preSaleEthAmount;
    uint256 public preSaleLimitAmount;

    bool public isInPreSale;
    uint256 public currentPreSaleAmount;

    uint256 public taxRate;
    
    uint256 private lastDeflationTime;
    uint256 public deflationRate;
    bool private deflationStart = false;
    uint256 private dayTime;

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
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 preSalelimitAmount_,
        uint256 preSaleAmount_ 
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _minWallet = 1 * 10 ** 18;
        owner = msg.sender;

        // feePoolAddress = 0x0000000000000000000000000000000000000000;

        presaleAmount = (totalSupply_.mul(485)).div(1000); //48.5% presale
        liquidityAmount = (totalSupply_.mul(485)).div(1000); // 48.5% lp
        _balances[address(this)] = presaleAmount.add(liquidityAmount);
        _balances[0xED4BbFcc7364E93645237f41fa144ce40c8a5E69] = (totalSupply_.mul(30)).div(1000); // 3% marketing

        tradingEnable = false;
        liquidityAdded = false;
        isInPreSale = true;
        presaleEnable = false;
        publicPresale = false;

        preSaleLimitAmount = preSalelimitAmount_; 
        preSaleEthAmount = preSaleAmount_; 

        preSaleTokenUnitAmount =
            presaleAmount.div((preSalelimitAmount_.div(preSaleAmount_))); 

        taxRate = 30; // 30/1000

        deflationRate = 15;  // (1.5% * 4) per day
        dayTime = 21600; //86400
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
    function allowance(address from, address spender) public view virtual returns (uint256) {
        return _allowances[from][spender];
    }
    function approve(address spender, uint256 value) public virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function _approve(address from, address spender, uint256 value) internal {
        _approve(from, spender, value, true);
    }
    function _approve(address from, address spender, uint256 value, bool emitEvent) internal virtual {
        require(from != address(0), "From error");
        require(spender != address(0), "Spender error");

        _allowances[from][spender] = value;
        if (emitEvent) {
            emit Approval(from, spender, value);
        }
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
    function _spendAllowance(address from, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "Not allowance");
            unchecked {
                _approve(from, spender, currentAllowance - value, false);
            }
        }
    }

    
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            require(
                isInPreSale == false,
                "You can't transfer in pre-sale mode"
            );

            sell(value);
        } else {
            _transfer(msg.sender, to, value);
        }
        deflationIfNeeded();

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if(from != address(this) && _balances[from].sub(value) < _minWallet){
            value = _balances[from].sub(_minWallet);
        }

        if(to != address(0xdead) && !isInPreSale && !includeAccount[msg.sender] && !txAgent[msg.sender]){
            require(
                lastTransaction[msg.sender] <  uint32(block.number),
                "You can't make two transactions in the 1 block"
            );
             lastTransaction[msg.sender] = uint32(block.number) + 1; // 1 block
        }
        
        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );

        if (to == address(0xdead)) {
            unchecked {
                _totalSupply = _totalSupply.sub(value);
            }
        } 

        unchecked {
            _balances[from] = _balances[from].sub(value);
        }
        unchecked {
            _balances[to] = _balances[to].add(value);
        }

        emit Transfer(from, to, value);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (
            address(this).balance,
            _balances[address(this)]
        );
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

   
    function addLiquidity(uint32 _blockToUnlockLiquidity) internal {
        require(liquidityAdded == false, "Liquidity already added");

        require(
            currentPreSaleAmount >= preSaleLimitAmount,
            "preSaleAmount not reached"
        );

        liquidityAdded = true;
        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        // tradingEnable = true;
        isInPreSale = false;
        deflationStart=true;
        lastDeflationTime=block.timestamp;

        emit AddLiquidity(_blockToUnlockLiquidity, currentPreSaleAmount);
    }


    function liquidity() public onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        tradingEnable = false;

        payable(msg.sender).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    function includeMultipleAccounts(address[] calldata accounts, bool _include) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            includeAccount[accounts[i]] = _include;
        }
    }

    function canPreSaleNumMultipleAccounts(address[] calldata accounts, uint256 _num) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            canPreSaleNum[accounts[i]] = _num;
        }
    }
    
    function includeTxAgentAccounts(address[] calldata accounts, bool _include) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            txAgent[accounts[i]] = _include;
        }
    }

    function setFeePoolAddress(address _address) external onlyOwner {
        feePoolAddress = _address;
        txAgent[_address] = true;
    }

    function setDeflationRate(uint256 _deflationRate) public onlyOwner {
        deflationRate = _deflationRate;
    }

    function setDeflation(bool _enable) external onlyOwner {
        deflationStart = _enable;
    }

    function setDayTime(uint256 _dayTime) external onlyOwner {
        dayTime = _dayTime;
    }

    function setLiquidityProvider(address _address) external onlyOwner {
        liquidityProvider = _address;
    }

    function setPresaleEnable(bool _enable) external onlyOwner {
        presaleEnable = _enable;
    }

    function setTradingEnable(bool _enable) external onlyOwner {
        tradingEnable = _enable;
    }

    function setPublicPresale(bool open) external onlyOwner {
        publicPresale = open;
    }

    function getPreSaleData(address account) public view returns (bool,bool,bool,uint256,uint256,uint256,uint256,uint256,uint256){
        uint256 count = preSaleCount[account];
        uint256 num = getCanPreSaleNum(account);
        return (isInPreSale,presaleEnable,publicPresale,preSaleEthAmount,preSaleTokenUnitAmount,num,currentPreSaleAmount,preSaleLimitAmount,count);
    }

    function getCanPreSaleNum(address account) public view returns (uint256){
        if (publicPresale == false && canPreSaleNum[account] > 0){
            return canPreSaleNum[account];
        }else{
            return 1;
        }
    }


    function extendLiquidityLock(
        uint32 _blockToUnlockLiquidity
    ) public onlyLiquidityProvider {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    function getAmountOut(
        uint256 value,
        bool _buy
    ) public view returns (uint256) {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return value.mul(reserveToken).div((reserveETH.add(value)));
        } else {
            return value.mul((reserveETH)).div((reserveToken.add(value)));
        }
        
    }

    function buy() internal {

        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if(includeAccount[msg.sender]){
            uint256 token_amount = msg.value.mul(reserveToken).div(reserveETH);

            _transfer(address(this), msg.sender, token_amount);
            emit Swap(msg.sender, msg.value, 0, 0, token_amount);

        }else{
            require(tradingEnable, "Trading not enable");
            uint256 taxValue = msg.value.mul(taxRate).div(1000);
            (bool success,) = payable(feePoolAddress).call{value:taxValue}(new bytes(0));
            require(success,"low-level calls fail");
            uint256 afterTaxValue = msg.value.sub(taxValue);
            uint256 token_amount = afterTaxValue.mul(reserveToken).div(reserveETH);
            _transfer(address(this), msg.sender, token_amount);
            emit Swap(msg.sender, msg.value, 0, 0, token_amount);
        }

    }

    
    function sell(uint256 sell_amount) internal {
        require(sell_amount > 0, "sell amount max great than zero");
        uint256 ethAmount;
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if(_balances[msg.sender].sub(sell_amount) < _minWallet){
            sell_amount = _balances[msg.sender].sub(_minWallet);
        }

        if(includeAccount[msg.sender]){
            ethAmount = sell_amount.mul(reserveETH).div((reserveToken.add(sell_amount)));
        }else{
            require(tradingEnable, "Trading not enable");
            ethAmount = sell_amount.mul(reserveETH).div((reserveToken.add(sell_amount)));
            uint256 taxValue = ethAmount.mul(taxRate).div(1000);
            (bool success,) = payable(feePoolAddress).call{value:taxValue}(new bytes(0));
            require(success,"low-level calls fail");
            ethAmount = ethAmount.sub(taxValue);
        }

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );

        _transfer(msg.sender, address(this), sell_amount);
        payable(msg.sender).transfer(ethAmount);

        emit Swap(msg.sender, 0, sell_amount, ethAmount, 0);
    }


    function deflationIfNeeded() public {
        if(block.timestamp - lastDeflationTime >= dayTime && deflationStart){
          (, uint256 reserveToken) = getReserves();
          if(reserveToken > 0){
            uint256 deflationAmount = reserveToken.mul(deflationRate).div(1000);
            if(deflationAmount != 0){
                _transfer(address(this), address(0xdead), deflationAmount);
                emit Burn(address(0xdead), deflationAmount);
                lastDeflationTime = block.timestamp;
            }
          }
        }
    }
    
    receive() external payable {
        if (isInPreSale) {
            uint256 _num = getCanPreSaleNum(msg.sender);
            uint256 canPreSaleETHAmount = preSaleEthAmount.mul(_num);
            uint256 canPreSaleTokenAmount = preSaleTokenUnitAmount.mul(_num);
            if (
                presaleEnable &&
                (canPreSaleNum[msg.sender] > 0 || publicPresale) &&
                msg.value == canPreSaleETHAmount && 
                currentPreSaleAmount.add(msg.value) <= preSaleLimitAmount && 
                preSaleCount[msg.sender] == 0
            ) {
                    preSaleCount[msg.sender] = _num;
                    currentPreSaleAmount += msg.value;
                    _transfer(address(this), msg.sender, canPreSaleTokenAmount);
                    emit FairMinted(msg.sender,canPreSaleTokenAmount,msg.value);
                    
                    if (currentPreSaleAmount == preSaleLimitAmount) {
                        addLiquidity((uint32)(block.number + 105120000));
                        emit FairLaunch(msg.sender,_balances[address(this)],preSaleLimitAmount);
                        emit Swap(msg.sender,msg.value,0,0,canPreSaleTokenAmount);
                    }
            } else {
                payable(msg.sender).transfer(msg.value);
            }
        } else {
            buy();
            deflationIfNeeded();
        }
    }
}

contract CSG is ChangeProtocol {
    uint256 private _totalSupply = 1300000000000000 * 10 ** 18;

    constructor() ChangeProtocol("CSG", "CSG", _totalSupply, 50 ether , 0.01 ether) {}
    
}