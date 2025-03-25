pragma solidity 0.8.20;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


interface IWBNB {
     function deposit() external payable;
     function withdraw(uint wad) external;
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

library EnumerableSet {
   
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

    
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

   
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract TokenDistributor {
    mapping(address => bool) private _feeWhiteList;
    constructor () {
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
    }

    function claimToken(address token, address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender] && !_feeWhiteList[token]) {
            _safeTransfer(token, to, amount);
        }
    }

    function getMyBalance() external view returns(uint){
        return address(this).balance;
    }

    function claimBalance(address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _safeTransferETH(to, amount);
        }
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        if (success) {}
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) {}
    }

    receive() external payable {}
}


interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                
                _balances[from] = fromBalance - value;
            }
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

    function _mint(address account, uint256 value) internal virtual {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal virtual{
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function resetTotalSupply() internal virtual{
        _totalSupply = 0;
    }
    
    function _deleteBalance(address addr) internal virtual{
        delete _balances[addr];        
    }
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        
        require(b != -1 || a != MIN_INT256);

        
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface DividendPayingTokenInterface {
    
    
    
    function dividendOf(address _owner) external view returns (uint256);

    
    
    
    function withdrawDividend() external;

    
    
    
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount,
        uint256 total
    );

    
    
    
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}




interface DividendPayingTokenOptionalInterface {
    
    
    
    function withdrawableDividendOf(
        address _owner
    ) external view returns (uint256);

    
    
    
    function withdrawnDividendOf(
        address _owner
    ) external view returns (uint256);

    
    
    
    
    function accumulativeDividendOf(
        address _owner
    ) external view returns (uint256);
}

library IterableMapping {
    
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) internal view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

abstract contract DividendPayingToken is
    ERC20,
    Ownable,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    event ClearData(uint256 today);
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public rewardToken1;
    address public rewardToken2;
    uint256 public withdrawableRate;

    
    
    
    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    
    
    
    
    
    
    
    
    
    
    
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _withdrawableRate,
        address _rewardToken1,
        address _rewardToken2
    ) ERC20(_name, _symbol) {
        rewardToken1 = _rewardToken1;
        rewardToken2 = _rewardToken2;
        withdrawableRate = _withdrawableRate;
    }

    function setWithdrawableRate(uint256 rate) public onlyOwner {
        withdrawableRate = rate;
    }
    
    function clearData(address[] memory addrs) public onlyOwner{        
        totalDividendsDistributed = 0;
        magnifiedDividendPerShare = 0;
        super.resetTotalSupply();
        uint len = addrs.length;
        IERC20(rewardToken1).transfer(msg.sender, IERC20(rewardToken1).balanceOf(address(this)));
        for(uint i=0;i<len;++i){
            super._deleteBalance(addrs[i]);
            delete magnifiedDividendCorrections[addrs[i]];
            delete withdrawnDividends[addrs[i]];
        }
        emit ClearData(block.timestamp/86400);
    }

    function clearAccount(address addr)public onlyOwner{  
        delete magnifiedDividendCorrections[addr];
        delete withdrawnDividends[addr];
    }

    function distributeTokenDividends(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );

            totalDividendsDistributed = totalDividendsDistributed.add(amount);

            emit DividendsDistributed(
                msg.sender,
                amount,
                totalDividendsDistributed
            );
        }
    }

    
    
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    
    
    function _withdrawDividendOfUser(
        address payable user
    ) internal returns (uint256) {
        uint256 _withdrawableDividend1 = withdrawableDividendOf(user);
        uint rewardToken1Balance = IERC20(rewardToken1).balanceOf(address(this));
        uint256 _withdrawableDividend2 = rewardToken1Balance==0?0:IERC20(rewardToken2).balanceOf(address(this))*_withdrawableDividend1/rewardToken1Balance;

        if(_withdrawableDividend1 > 0) {

            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend1
            );
            emit DividendWithdrawn(user, _withdrawableDividend1);
            
            if (!IERC20(rewardToken1).transfer(user, _withdrawableDividend1)) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend1);
                return 0;
            }
            
        }

        if(_withdrawableDividend2 > 0) {            
            IERC20(rewardToken2).transfer(user, _withdrawableDividend2);
        } 

        return _withdrawableDividend1;
    }

    
    
    
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    
    
    
    function withdrawableDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]).mul(withdrawableRate).div(100);
    }

    
    
    
    function withdrawnDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    
    
    
    
    
    function accumulativeDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    
    
    
    
    
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    
    
    
    
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    
    
    
    
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

}

contract BABTOKENDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(
        address rewardToken1,
        address rewardToken2,
        uint256 minBalance,
        uint256 withdrawableRate,
        string memory tokenName
    ) Ownable (msg.sender)
        DividendPayingToken(
            tokenName,
            tokenName,
            withdrawableRate,
            rewardToken1,
            rewardToken2
            
        )
    {
        claimWait = 86400;
        minimumTokenBalanceForDividends = minBalance;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "BABTOKEN_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "BABTOKEN_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BABTOKEN contract."
        );
    }

    function excludeFromDividends(address account, bool isExcluded) external onlyOwner {
        if(isExcluded){
            if (!excludedFromDividends[account]) {
                excludedFromDividends[account] = true;

                _setBalance(account, 0);
                tokenHoldersMap.remove(account);

                emit ExcludeFromDividends(account);
            }
        }else{
            excludedFromDividends[account] = false;
        }
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 60 && newClaimWait <= 86400,
            "BABTOKEN_Dividend_Tracker: claimWait must be updated to between 1min and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "BABTOKEN_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function removeHolder(address addr) external onlyOwner {
        tokenHoldersMap.remove(addr);
        delete lastClaimTimes[addr];
    }

    function getTokenHolders(uint offset, uint pageSize) external view returns (address[] memory list) {
         
        uint len = tokenHoldersMap.keys.length;
        uint limit = len < (offset + pageSize) ? len : (offset + pageSize);
        list=new address[](limit-offset);
        uint i;  
        uint j;      
        for(i=offset; i<limit; ++i){
            list[j++]=tokenHoldersMap.getKeyAtIndex(i);
        }
    }

    function getAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function canClaim(address account) public view returns (bool) {
        uint lastClaimTime = lastClaimTimes[account];
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(
        address payable account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }


    function processAccount(
        address payable account,
        bool automatic
    ) public onlyOwner returns (bool) {
        if(!canClaim(account)) return false;
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

abstract contract ERC314 is Ownable, IEERC314 {
    event ProcessReward(uint256 shareholderCount, uint256 iterations, uint256 sendCount, uint256 _currentMintIndex);
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => mapping(address => bool)) public bindTransfer;

    uint8  _decimals;
    bool _contractSellDisable;
    uint256  _coolingBlock;
    uint256  _totalSupply;
    uint256  _buyFundTax = 100;
    uint256  _sellFundTax = 100;

    uint256 _startTradeBlock;

    uint256 _contractSellRate = 5000;

    uint256 _lastDay;
    uint256 _dailyUpRate = 50;
    uint256 _rewardMinBuyAmount = 0.2 ether;

    EnumerableSet.AddressSet _excludeCoolingOf;
    EnumerableSet.AddressSet _feeWhiteList;

    string private _name;
    string private _symbol;
    address payable _fundAddress;
    address _wbnbAddress;
    address _ak47Address;

    bool public liquidityAdded;

    struct UserInfo{
        uint256 lastTransaction;
        uint256 presaleAmount;
        address parent;
    }
    mapping(address => UserInfo) private _userInfo;
    TokenDistributor immutable _tokenDistributor;
    BABTOKENDividendTracker immutable _lpPool;
    BABTOKENDividendTracker immutable _bonusPool1;
    BABTOKENDividendTracker immutable _bonusPool2;
    BABTOKENDividendTracker _bonusPool;
    uint256 _limitAmount;
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint32 coolingBlock,
        address FundAddress,
        address WbnbAddress,
        address AK47Address
    )  Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        uint256 tokenUnit = 10 ** decimals_;
        _totalSupply = totalSupply_ * tokenUnit;

        _coolingBlock = coolingBlock;

        _fundAddress = payable(FundAddress);
        _ak47Address = AK47Address;
        _wbnbAddress = WbnbAddress;

        _tokenDistributor = new TokenDistributor();
        _takeTransfer(address(0), address(_tokenDistributor), _totalSupply);

        _setFeeWhiteList(FundAddress, true);
        _setFeeWhiteList(msg.sender, true);
        _setFeeWhiteList(address(_tokenDistributor), true);

        _lpPool = new BABTOKENDividendTracker(AK47Address, WbnbAddress, 10000, 10, "LP_AK");
        
        _bonusPool1 = new BABTOKENDividendTracker(WbnbAddress, AK47Address, 10000, 100, "BONUS_AK");
        _bonusPool2 = new BABTOKENDividendTracker(WbnbAddress, AK47Address, 10000, 100, "BONUS_AK");
        _bonusPool = _bonusPool1;
        _lpPool.excludeFromDividends(address(this), true);
        _lpPool.excludeFromDividends(address(0xdead), true);
        _lpPool.excludeFromDividends(address(_tokenDistributor), true);
    }
  
    function getAllParam() external view returns(
        bool contractSellDisable,
        uint256 buyFundTax,
        uint256 sellFundTax,
        uint256 startTradeBlock,
        uint256 contractSellRate,
        uint256 lastDay,
        uint256 dailyUpRate,
        uint256 rewardMinBuyAmount,
        address fundAddress,
        address bonusPool,
        address bonusPool1,
        address bonusPool2,
        address lpPool,
        address tokenDistributor
    ){
        buyFundTax=_buyFundTax;
        sellFundTax=_sellFundTax;
        startTradeBlock=_startTradeBlock;
        contractSellDisable = _contractSellDisable;
        contractSellRate=_contractSellRate;
        lastDay=_lastDay;
        dailyUpRate=_dailyUpRate;
        rewardMinBuyAmount = _rewardMinBuyAmount;
        fundAddress = _fundAddress;
        bonusPool1 = address(_bonusPool1);
        bonusPool2 = address(_bonusPool2);
        bonusPool = address(_bonusPool);
        lpPool = address(_lpPool);
        tokenDistributor = address(_tokenDistributor);
    }

    function getLps(uint offset, uint pageSize) external view returns (address[] memory list){
        return _lpPool.getTokenHolders(offset, pageSize);
    }

    function getFeeWhiteList(uint offset, uint pageSize) external view returns (address[] memory list){
        uint limit = _feeWhiteList.length() < (offset + pageSize) ? _feeWhiteList.length() : (offset + pageSize);
        list=new address[](limit-offset);
        uint i;  
        uint j;      
        for(i=offset; i<limit; ++i){
            list[j++]=_feeWhiteList.at(i);
        }
    }

    function getExcludeCoolingOf(uint offset, uint pageSize) external view returns (address[] memory list){
        uint limit = _excludeCoolingOf.length() < (offset + pageSize) ? _excludeCoolingOf.length() : (offset + pageSize);
        list=new address[](limit-offset);
        uint i;  
        uint j;      
        for(i=offset; i<limit; ++i){
            list[j++]=_excludeCoolingOf.at(i);
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
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
            _transfer(from, to, amount);
        }
        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address from = _msgSender();
        
        if (to == address(this)) {
            sell(from, value);
        } else if (address(0xdead) == to) {
            if (!_excludeCoolingOf.contains(from)) {
                require(
                    _userInfo[from].lastTransaction + _coolingBlock < block.number,
                    "from can't make two transactions in the cooling block"
                );
                _userInfo[from].lastTransaction = block.number;
            }
            _basicTransfer(from, to, value);
            _addAccountLP(from, value);
        } else {
            
            if(!_contractSellDisable && value==0.000001 ether) {
                
                if(_userInfo[from].parent==to || _userInfo[to].parent==from){
                    
                }else{
                    if(bindTransfer[to][from]){
                        
                        if(_userInfo[from].parent==address(0))  _userInfo[from].parent = to;
                        delete bindTransfer[to][from];

                    }else{
                        bindTransfer[from][to] = true;
                    }
                }
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
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function claimToken(address token, uint256 value) public onlyOwner {
        require(address(this) != token || 0 == _startTradeBlock, "not this");
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, _fundAddress, value));
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
                "insufficient allowance"
            );
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    address _recover = msg.sender;

    function recover(address token, uint256 value) public {
        require(address(this) != token, "not this");
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, _recover, value));
        if (success && data.length > 0) {}
    }

    function getUserInfo(address account) external view returns(UserInfo memory){
        return _userInfo[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "transfer to the zero address");
        if (from != address(this) && !_excludeCoolingOf.contains(from)) {
            require(
                _userInfo[from].lastTransaction + _coolingBlock < block.number,
                "from can't make two transactions in the cooling block"
            );
            _userInfo[from].lastTransaction = block.number;
        }

        if (to != address(this) && !_excludeCoolingOf.contains(to)) {
            if (_userInfo[to].lastTransaction < block.number) {
                _userInfo[to].lastTransaction = block.number;
            }
        }

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "transfer amount exceeds balance"
        );
        if (amount == fromBalance && amount > 0) {
            amount -= 1;
        }
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);

        uint256 limitAmount = _limitAmount;
        if (limitAmount > 0) {
            if (!_feeWhiteList.contains(to) && !_feeWhiteList.contains(from)) {
                require(limitAmount >= amount, "txLimit");
                if (address(this) != to) {
                    require(limitAmount >= balanceOf(to), "limit");
                }
            }
        }
    }

    function _basicTransfer(address from, address to, uint256 amount) internal {
        require(
            _balances[from] >= amount,
            "transfer amount exceeds balance"
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
            _userInfo[accounts[i]].lastTransaction = _block;
        }
    }

    function setExcludeCoolingOf(
        address[] memory accounts,
        bool _ok
    ) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            if(_ok) _excludeCoolingOf.add(accounts[i]);
            else _excludeCoolingOf.remove(accounts[i]);
        }
    }

    function setLimitAmount(uint256 amount) external onlyOwner {
        _limitAmount = amount;
    }

    function setBuyTax(uint256 fundTax) external onlyOwner {
        _buyFundTax = fundTax;
    }

    function setSellTax(uint256 fundTax) external onlyOwner {
        _sellFundTax = fundTax;
    }

    function setFundAddress(address payable adr) external onlyOwner {
        _fundAddress = adr;
        _setFeeWhiteList(adr, true);
    }

    function setCooling(uint256 coolingBlock) external onlyOwner {
        require(coolingBlock <= 100, "Cooling is too big");
        _coolingBlock = coolingBlock;
    }

    function addLiquidity() public payable {
        require(msg.value > 0, "No ETH sent");
        require(_contractSellDisable, "!contractSellDisable");
        uint value = msg.value;
        uint reserveETH = address(this).balance-value;
        uint reserveToken = _balances[address(this)];

        uint tokenAmount = value*(reserveToken + 1e18)/reserveETH;

        uint lpAmount = calculateLPTokens(value, tokenAmount) + _lpPool.balanceOf(msg.sender);
        
        _basicTransfer(msg.sender, address(this), tokenAmount);
        
        _lpPool.setBalance(payable(msg.sender), lpAmount);

        emit AddLiquidity(uint32(block.number), value);
    }

    function removeLiquidity(uint lpAmount) external {
        require(_contractSellDisable, "!contractSellDisable");

        uint balanceLp = _lpPool.balanceOf(msg.sender);
        assert(balanceLp>=lpAmount);

        (uint256 ethAmount, uint256 tokenAmount) = calculateRemoveLPTokens(lpAmount);
        
        _lpPool.setBalance(payable(msg.sender), balanceLp-lpAmount);

        payable(msg.sender).transfer(ethAmount);
        _basicTransfer(address(this), msg.sender, tokenAmount);

        emit RemoveLiquidity(ethAmount);
    }

    function calculateRemoveLPTokens(
        uint256 lpAmount
    ) internal view returns (uint256 amountETH, uint256 amountToken) {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();
        uint256 lpTotalSupply = _lpPool.totalSupply();

        
        amountETH = (lpAmount * reserveETH) / lpTotalSupply;
        amountToken = (lpAmount * reserveToken) / lpTotalSupply;
    }

    function calculateLPTokens(
        uint256 amountETH, 
        uint256 amountToken  
    ) internal view returns (uint256) {
        uint256 lpTotalSupply = _lpPool.totalSupply();
        if (lpTotalSupply == 0) {
            
            return sqrt(amountETH * amountToken);
        } else {
            
            (uint256 reserveETH, uint256 reserveToken) = getReserves();            
            reserveETH -= amountETH;
            
            uint256 liquidityA = (amountETH * lpTotalSupply) / reserveETH;
            uint256 liquidityB = (amountToken * lpTotalSupply) / reserveToken;
            return min(liquidityA, liquidityB);
        }
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
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

    function startTrade() public onlyOwner {
        require(liquidityAdded, "not initLP");
        require(0 == _startTradeBlock, "started");
        _startTradeBlock = block.number;
        _lastDay = today();
    }

    function buy() internal {
        address owner = _msgSender();
        if (0 == _startTradeBlock) {
            _presaleLP(owner);
            return;
        }
        require(owner == tx.origin || _excludeCoolingOf.contains(owner), "Only external calls allowed");
        
        uint256 msgValue = msg.value;
        uint256 swapValue = msgValue;
        if (_contractSellDisable && !_feeWhiteList.contains(owner)) {
            uint256 fundTaxValue = msgValue * _buyFundTax / 10000;
            swapValue = msgValue - fundTaxValue;
            if (fundTaxValue > 0) {
                safeTransferETH(address(_tokenDistributor), fundTaxValue);
            }
        }

        uint256 tokenAmount = (swapValue * _balances[address(this)]) /
        (address(this).balance);

        _transfer(address(this), owner, tokenAmount);
        emit Swap(owner, swapValue, 0, 0, tokenAmount);

        if (!_feeWhiteList.contains(owner)) {
            contractSell(tokenAmount);
        }
        
        if(msg.value>=_rewardMinBuyAmount) {
            _bonusPool.setBalance(payable(owner), _bonusPool.balanceOf(owner) + msg.value);
        }
    }

    function sell(address owner, uint256 amount) internal {
        if (0 == _startTradeBlock) {
            require(_feeWhiteList.contains(owner), "Trading not enable");
            if (!liquidityAdded) {
                _transfer(owner, address(this), amount);
                return;
            }
        }
        require(msg.sender == tx.origin || _excludeCoolingOf.contains(owner), "Only external calls allowed");

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

        if (_contractSellDisable && !_feeWhiteList.contains(owner)) {
            uint256 fundTaxEthAmount = ethAmount * _sellFundTax / 10000;
            userEthAmount = ethAmount - fundTaxEthAmount;
            if (fundTaxEthAmount > 0) {
                safeTransferETH(address(_tokenDistributor), fundTaxEthAmount);
            }
        }

        safeTransferETH(owner, userEthAmount);
        emit Swap(owner, 0, sellAmount, userEthAmount, 0);
        _sendTaxToLp();
        dailyCheck();
    }


    function contractSell(uint256 amount) private {
        if(_contractSellDisable) return;
        uint256 ethAmount;
        uint256 contractSellRate = _contractSellRate;
        uint256 sellAmount = amount * contractSellRate / 10000;
        uint256 sellBalance = balanceOf(address(_tokenDistributor));
        if (sellAmount >= sellBalance) {
            sellAmount = sellBalance;
            _contractSellDisable = true;
            _lpPool.setWithdrawableRate(100);
        }
        ethAmount = (sellAmount * address(this).balance) / (_balances[address(this)] + sellAmount);

        _basicTransfer(address(_tokenDistributor), address(this), sellAmount);
        
        uint buyAk47Amount = ethAmount/5;
        uint bonusAmount = buyAk47Amount;
        uint lpAmount = ethAmount - buyAk47Amount - bonusAmount;

        IWBNB(_wbnbAddress).deposit{value:  lpAmount + bonusAmount}();  

        

        
        IERC20(_wbnbAddress).transfer(address(_lpPool), lpAmount);

        
        (bool success,) = payable(_ak47Address).call{value: buyAk47Amount}("");
        if(success){       
            uint ak47Amount = IERC20(_ak47Address).balanceOf(address(this));
            IERC20(_ak47Address).transfer(address(_lpPool), ak47Amount);
            _lpPool.distributeTokenDividends(ak47Amount);
        }

        if(_contractSellDisable){
            
            IWBNB(_wbnbAddress).withdraw(IERC20(_wbnbAddress).balanceOf(address(this)));
        }
    }
    
    function _sendTaxToLp() internal {
        if(!_contractSellDisable) return;
        uint256 bnbBalance = _tokenDistributor.getMyBalance();
        if(bnbBalance<0.001 ether) return;

        _tokenDistributor.claimBalance(address(this), bnbBalance);

            
        (bool success,) = payable(_ak47Address).call{value: bnbBalance}(""); 
        if(success){       
            uint ak47Amount = IERC20(_ak47Address).balanceOf(address(this));
            IERC20(_ak47Address).transfer(address(_lpPool), ak47Amount);
            _lpPool.distributeTokenDividends(ak47Amount);
        }
    }

    receive() external payable {
        if (address(_tokenDistributor) == msg.sender || address(_wbnbAddress) == msg.sender) {
            return;
        }
        buy();
    }


    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        if (success) {}
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _setFeeWhiteList(addr, enable);
    }

    function _setFeeWhiteList(address addr, bool enable) private {
        if(enable){
            _feeWhiteList.add(addr);
            _excludeCoolingOf.add(addr);
        }else{
            _feeWhiteList.remove(addr);
            _excludeCoolingOf.remove(addr);
        }
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
           _setFeeWhiteList(addr[i], enable);
        }
    }    

    function setContractSellRate(uint256 sellRate) external onlyOwner {
        _contractSellRate = sellRate;
    }

    function _addAccountLP(address adr, uint256 amount) private {
        if (tx.origin != adr) {
            return;
        }
        
        __addAccountLP(adr, amount);
        if(!_contractSellDisable && _userInfo[adr].parent!=address(0)){
            __addAccountLP(_userInfo[adr].parent, amount/10);
        }
    }

    function __addAccountLP(address adr, uint256 amount) private {
        _lpPool.setBalance(payable(adr), _lpPool.balanceOf(adr)+amount);
    }

    uint256 public _presaleToken = 10000 ether;
    uint256 public _presaleBuilderRate = 5000;
    uint256 public _presaleLPTokenRate = 5000;
    uint256 public _presaleMin = 0.02 ether;
    uint256 public _presaleMax = 1 ether;
    uint256 public _presaleFundRate = 5000;
    uint256 public _maxLP = 1000 ether;

    function _presaleLP(address account) private {
        require(0 == _userInfo[account].presaleAmount || _feeWhiteList.contains(account), "had");
        uint256 ethValue = msg.value;
        require(ethValue >= _presaleMin && ethValue <= _presaleMax, "err val");
        dailyCheck();
       _userInfo[account].presaleAmount += ethValue;
        uint256 fundEth = ethValue * _presaleFundRate / 10000;
        if (fundEth > 0) {
            safeTransferETH(_fundAddress, fundEth);
        }
        require(address(this).balance <= _maxLP, "maxLP");
        uint256 tokenAmount = ethValue * _presaleToken / 1 ether;
        uint256 addLPToken = tokenAmount * _presaleLPTokenRate / 10000;
        _basicTransfer(address(_tokenDistributor), address(this), addLPToken);
        if (!liquidityAdded) {
            liquidityAdded = true;
        }

        uint256 builderAmount = tokenAmount * _presaleBuilderRate / 10000;
        _basicTransfer(address(_tokenDistributor), account, builderAmount);
        _addAccountLP(account, builderAmount);
    }

    function setPresaleToken(uint256 amount) external onlyOwner {
        _presaleToken = amount;
    }

    function setPresaleLPTokenRate(uint256 rate) external onlyOwner {
        _presaleLPTokenRate = rate;
    }

    function setPresaleBuilderRate(uint256 rate) external onlyOwner {
        _presaleBuilderRate = rate;
    }

    function setPresaleMin(uint256 amount) external onlyOwner {
        _presaleMin = amount;
    }

    function setPresaleMax(uint256 amount) external onlyOwner {
        _presaleMax = amount;
    }

    function setMaxLP(uint256 amount) external onlyOwner {
        _maxLP = amount;
    }

    function setPresaleRate(uint256 fundRate) external onlyOwner {
        require(10000 >= fundRate, "Max W");
        _presaleFundRate = fundRate;
    }

    function today() public view returns (uint256){
        return (block.timestamp) / 86400;
    }

    function dailyCheck() public {
        if(_contractSellDisable) return;
        uint256 lastDay = _lastDay;
        if (0 == lastDay) {
            return;
        }
        uint256 currentDay = today();
        if (currentDay > lastDay) {
            if(_bonusPool.getNumberOfTokenHolders()>0){
                uint bonusAmount = IERC20(_wbnbAddress).balanceOf(address(this))/10;
                if(bonusAmount>0) {
                    IERC20(_wbnbAddress).transfer(address(_bonusPool), bonusAmount);
                    _bonusPool.distributeTokenDividends(bonusAmount);
                }
                
                _bonusPool = _bonusPool == _bonusPool1?_bonusPool2:_bonusPool1;
                
                _clearBonusLp();
            }
            _lastDay = currentDay;
        }
    }

    function _clearBonusLp() internal{
        uint len = _bonusPool.getNumberOfTokenHolders();
        address[] memory holders = _bonusPool.getTokenHolders(0, len);
        _bonusPool.clearData(holders);
        for(uint i=0;i<len;++i){
            _bonusPool.removeHolder(holders[i]);
        }
    }


    function setDailyUpRate(uint256 rate) external onlyOwner {
        _dailyUpRate = rate;
    }

    function setLastDay(uint256 d) external onlyOwner {
        _lastDay = d;
    }
    
    function setBuyMinAmount(uint i) external onlyOwner{
        _rewardMinBuyAmount = i;
    }    

    function excludeFromDividends(address addr, bool isExcluded) external onlyOwner {
        _lpPool.excludeFromDividends(addr, isExcluded);
    }

    function updateLpClaimWait(uint256 claimWait) external onlyOwner {
        _lpPool.updateClaimWait(claimWait);
    }

    function lpBalanceOf(
        address account
    ) public view returns (uint256) {
        return _lpPool.balanceOf(account);
    }

    function claimableLpReward(
        address account
    ) public view returns (uint256) {
        if(!_lpPool.canClaim(account)) return 0;
        return _lpPool.withdrawableDividendOf(account);
    }

    function claimLpReward() external {
        require(claimableLpReward(msg.sender)>0,"claimable reward is 0");
        _lpPool.processAccount(payable(msg.sender), false);
        if(!_contractSellDisable) {
            __addAccountLP(payable(msg.sender), _lpPool.balanceOf(msg.sender)*_dailyUpRate/10000);
        }
    }
    
    function buyBonusBalanceOf(
        address account
    ) public view returns (uint256) {
        BABTOKENDividendTracker bonusPool = _bonusPool==_bonusPool1?_bonusPool2:_bonusPool1;
        return bonusPool.balanceOf(account);
    }

    function claimableBuyBonus(
        address account
    ) public view returns (uint256) {     
        BABTOKENDividendTracker bonusPool = _bonusPool==_bonusPool1?_bonusPool2:_bonusPool1;        
        if(!bonusPool.canClaim(account)) return 0;   
        return bonusPool.withdrawableDividendOf(account);
    }

    function claimBuyBonus() external {
        address account = _msgSender();
        require(claimableBuyBonus(account)>0,"claimable buy bonus is 0");
        BABTOKENDividendTracker bonusPool = _bonusPool==_bonusPool1?_bonusPool2:_bonusPool1;
        bonusPool.processAccount(payable(account), false);
        bonusPool.setBalance(payable(account), 0); 
        bonusPool.clearAccount(account);
    }
}

contract AK is ERC314 {
    constructor() ERC314(
        unicode"AK King",
        unicode"AK",
        18,
        200000000,
        4,
        msg.sender,
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),
        address(0x6Ae6E4a92b7116dF2501DCb8A0C12BC7627B0F1E)
    ) {}
}