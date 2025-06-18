// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: HyperBroProtocol.sol


pragma solidity ^0.8.0;

// Importaciones de OpenZeppelin (manteniendo las versiones especificadas)


// SafeMath no es necesario en Solidity ^0.8.0, ya ha sido eliminado
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/math/SafeMath.sol"; // REMOVED

// Se necesita importar IERC20 para la llamada externa si se usara, aunque withdrawMarketingFunds se eliminó, el import no molesta.



contract HyperBroProtocol is ERC20, Ownable, Pausable {
    // SafeMath eliminado ya que Solidity ^0.8.0 maneja overflows/underflows
    // using SafeMath for uint256; // REMOVED

    // --- Tokenomics Initial ---
    uint256 private constant _totalSupply = 1_000_000_000 * (10**18); // 1 Billion HYPBRO with 18 decimals
    uint256 private constant _initialLiquidityPercentage = 25; // Percentage for initial LP burn
    uint256 private constant _communityPercentage = 25; // Percentage for community distribution
    uint256 private constant _creatorPercentage = 43; // Percentage for creator (locked)
    // Calculate the marketing percentage directly to ensure it's the remainder
     uint256 private constant _marketingPercentage = 100 - _initialLiquidityPercentage - _communityPercentage - _creatorPercentage; // Should be 7%

    // --- Fees and Burns (Renamed Reflection Fee to Marketing Fee) ---
    uint256 public burnFee = 1; // 1% burn (standard)
    uint256 public marketingFee = 2; // 2% sent to marketing wallet (renamed from reflectionFee)
    uint256 public totalFee = burnFee + marketingFee; // Calculated total fee

    // --- Anti-Bot and Anti-Whale ---
    bool public tradingEnabled = false; // Flag to enable trading after LP is added
    // Max transaction amount limit (e.g., 2% of total supply)
    uint256 private _maxTxAmount = _totalSupply * 2 / 100; // Adjusted arithmetic without SafeMath
    mapping(address => bool) private _isExcludedFromFee; // Wallets excluded from fees (e.g., liquidity pool, creator, marketing)

    // --- Creator Lock (Duration Increased) ---
    uint256 public creatorLockEndTime; // Timestamp when creator lock ends
    uint256 private constant _lockDuration = 45 days; // Lock duration set to 45 days

    // --- Designated Wallets (Set in Constructor) ---
    // These are immutable, set once by the deployer via constructor parameters
    address public immutable creatorWallet;
    address public immutable marketingWallet;

    // --- State variable to track distribution ---
    bool public tokensAlreadyDistributed = false; // Flag to ensure manual distribution runs only once


    // --- Migration V2 (Optional Future) ---
    bool public migrationEnabled = false; // Flag to enable future migration
    address public newContractAddress; // Address of the V2 contract (set via owner function)

    // --- Events (Renamed Reflection Fee Event) ---
    // Event emitted when fees are updated (reflects new marketingFee name)
    event FeesUpdated(uint256 newBurnFee, uint256 newMarketingFee);
    // Event emitted when trading is enabled
    event TradingEnabled();
    // Event emitted when max transaction amount is updated
    event MaxTxAmountUpdated(uint256 newMaxTxAmount);
    // Event emitted when migration address is set
    event MigrationInitiated(address indexed newContract);
    // Event emitted after successful manual token distribution
    event ManualDistributionPerformed();


    // Constructor: Called only once upon contract deployment.
    // Takes creator and marketing wallet addresses as parameters from the deployer.
    constructor(address _creatorWallet, address _marketingWallet) ERC20("HyperBro Protocol", "HYPBRO") {
        // Set the designated wallets using the constructor parameters
        require(_creatorWallet != address(0), "Creator wallet cannot be zero address");
        require(_marketingWallet != address(0), "Marketing wallet cannot be zero address");
        creatorWallet = _creatorWallet;
        marketingWallet = _marketingWallet;

        // Transfer ownership to the designated creator wallet immediately
        // This is safe because we require valid addresses above.
        transferOwnership(creatorWallet);

        // Mint the total supply to the contract address initially.
        // Tokens are held here until manualDistributeTokens() is called.
        _mint(address(this), _totalSupply);

        // Initial transfers and burns are deferred to manualDistributeTokens()
        // to simplify the constructor and avoid gas issues during deployment.

        // Exclude key wallets from fees from the start.
        // Creator and marketing wallets are excluded so fee mechanism doesn't interfere with their designated use.
        _isExcludedFromFee[creatorWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true; // Contract address itself is excluded

        // Optional: Exclude PancakeSwap router or other exchange addresses if needed
        // Example: address pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256e843; // PancakeSwap Router V2
        // _isExcludedFromFee[pancakeRouter] = true; // Exclude this router if needed (needs to be done post-deploy via excludeFromFee if not constant)

        // creatorLockEndTime should be set AFTER tokens are in creatorWallet (in manualDistributeTokens)
        // Setting it here would start the timer immediately on deploy, which is not the intended behavior.
        // This line is explicitly removed from the constructor.
        // creatorLockEndTime = block.timestamp + _lockDuration; // REMOVED from constructor
    }

    // --- Function to manually distribute tokens AFTER deployment ---
    // This function is intended to be called exactly ONCE by the owner
    // after the contract is deployed and before trading is enabled.
    function manualDistributeTokens() external onlyOwner {
        // Ensure this function is called only once for security and accuracy.
        require(!tokensAlreadyDistributed, "Initial tokens already distributed");

        // Calculate amounts based on static percentages.
        // Adjusted arithmetic without SafeMath.
        uint256 initialLiquidityAmount = _totalSupply * _initialLiquidityPercentage / 100;
        uint256 communityAmount = _totalSupply * _communityPercentage / 100;
        uint256 creatorAmountToTransfer = _totalSupply * _creatorPercentage / 100;
        // Marketing amount is the remainder to ensure total supply is fully accounted for.
        uint256 marketingAmountToSend = _totalSupply - initialLiquidityAmount - communityAmount - creatorAmountToTransfer;

        // CRITICAL CHECK: Ensure the contract holds the FULL supply amount required for distribution.
        // This ensures we actually have the tokens to move.
        // We keep the check that the balance is >= the total required sum.
        require(balanceOf(address(this)) >= initialLiquidityAmount + communityAmount + creatorAmountToTransfer + marketingAmountToSend, "Not enough tokens in contract to perform distribution");

        // **RELAXED CHECK:** Removed the strict equality check (balance == totalSupply) to avoid issues
        // if there's a tiny discrepancy (e.g., due to smallest unit movement or precision).
        // The previous line already ensures we have *enough* tokens to cover the calculated distribution.
        // require(balanceOf(address(this)) == _totalSupply, "Contract balance does not match total supply, cannot distribute"); // REMOVED strict equality check


        // --- Perform the transfers from the contract's balance to the designated wallets ---

        // Transfer initial liquidity amount to the burn address.
        // This signifies the tokens dedicated for LP that will be burned with LP tokens later.
        _transfer(address(this), address(0), initialLiquidityAmount);

        // Transfer community tokens to the designated community wallet.
        address communityWallet = 0xF6D31f40A48008F5A7a9a97247c0ad18547ED133; // Specified community wallet address
        require(communityWallet != address(0), "Community wallet address cannot be zero"); // Basic check for community wallet address
        _transfer(address(this), communityWallet, communityAmount);

        // Transfer creation tokens to the creator's wallet.
        _transfer(address(this), creatorWallet, creatorAmountToTransfer);

        // Transfer the remaining supply to the marketing wallet.
        _transfer(address(this), marketingWallet, marketingAmountToSend);


        // Set the creator lock end time NOW, after the tokens have been transferred to the creator's wallet.
        // This starts the 45-day timer from the moment of actual distribution.
        creatorLockEndTime = block.timestamp + _lockDuration;


        // Mark the distribution process as completed permanently.
        tokensAlreadyDistributed = true;
        // Emit an event to log that distribution has occurred.
        emit ManualDistributionPerformed();

         // After this function runs, the tokens are in their respective initial wallets/burn address.
         // Trading is still disabled. The owner must call enableTrading() to allow swaps.
    }

    // --- Internal Transfer Logic (_transfer override) ---
    // ERC20 transfer function overridden to include custom fees, anti-whale, anti-bot, and lock logic.
    function _transfer(address from, address to, uint256 amount) internal override {
        // Basic require checks from ERC20 standard
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // --- Creator Lock Logic ---
        // Prevents transfers *from* the creator wallet before the lock time ENDS.
        // Exception: allow the VERY FIRST transfer from creatorWallet for initial LP addition
        // (this happens *after* manual distribution but *before* trading is explicitly enabled).
        // The lock only applies *after* tokens have been distributed manually.
        if (tokensAlreadyDistributed && from == creatorWallet && block.timestamp < creatorLockEndTime) {
             // If distribution is done, and lock is active, ALLOW transfer from creator wallet ONLY if trading is NOT enabled.
             // This specifically allows the initial LP addition transfer from the creator wallet to the PancakeSwap router.
             require(!tradingEnabled, "Creator tokens are locked until the lock period ends");
        }

        // --- Anti-Bot & Trading Enable Logic ---
        // Prohibit trading (transfers between non-owner/non-excluded wallets) before it's officially enabled.
        // This prevents bots from buying/selling before you add liquidity and announce trading.
        // Ensures this check does NOT block transfers FROM the contract address (during manual distribution) or to/from owner/excluded wallets.
         if (!tradingEnabled && from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != address(this)) {
            require(false, "Trading is not enabled yet"); // Trading is disabled
        }

        // --- Bypass Fees/Checks During Manual Distribution ---
        // If the transfer is originating FROM the contract address AND the manual distribution is NOT marked as complete,
        // it's part of the initial distribution process. These transfers must happen without fees or other trading checks.
         if (from == address(this) && !tokensAlreadyDistributed) {
             super._transfer(from, to, amount); // Perform the direct transfer without fees
             return; // Exit the function after handling distribution transfer
         }


        // --- Anti-Whale Logic ---
        // Limit the maximum transaction amount for wallets that are NOT excluded from fees.
         if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maximum allowed transaction amount");
        }

        // --- Fee Calculation and Application ---
        // Apply fees only if the sender OR receiver are NOT in the excluded list.
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
             super._transfer(from, to, amount); // Standard transfer for excluded wallets (no fees)
        } else {
            // Calculate fee amounts based on the transfer amount.
            // Adjusted arithmetic without SafeMath.
            uint256 burnAmount = amount * burnFee / 100;
            uint256 marketingAmount = amount * marketingFee / 100; // Use marketingFee
            uint256 transferAmount = amount - burnAmount - marketingAmount; // Amount left to transfer

            // Perform the burn: send burnAmount to the zero address.
            super._transfer(from, address(0), burnAmount);
            // Distribute the marketing fee to the marketing wallet.
            super._transfer(from, marketingWallet, marketingAmount); // Send marketingFee to marketing wallet
            // Transfer the remaining amount to the final recipient.
            super._transfer(from, to, transferAmount);
        }
    }

    // --- Owner Functions ---
    // Functions callable only by the contract owner (creatorWallet).

    // Function to enable trading after LP is added and distribution is done.
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        // Ensure manual distribution has been performed before enabling trading.
        require(tokensAlreadyDistributed, "Initial tokens must be distributed first");
        tradingEnabled = true; // Set trading status to true
        emit TradingEnabled(); // Emit event
    }

    // Function to update the burn and marketing fees.
    // Only adjustable by the owner within the first 45 days lock period.
    // Takes new burn and marketing fees as parameters.
    function updateFees(uint256 _burnFee, uint256 _marketingFee) external onlyOwner {
         // Fees can be updated only after distribution and while the creator lock is active.
        require(tokensAlreadyDistributed, "Initial tokens must be distributed before updating fees");
        require(block.timestamp <= creatorLockEndTime, "Fees can only be updated within the first 45 days");
        // Basic validation for fee percentage ranges.
        require(_burnFee <= 3 && _marketingFee <= 3, "Fees cannot exceed 3%"); // Fee caps
        // Update fee state variables.
        burnFee = _burnFee;
        marketingFee = _marketingFee; // Update marketingFee
        totalFee = burnFee + marketingFee; // Update total fee
        // Emit event with updated fees.
        emit FeesUpdated(burnFee, marketingFee);
    }

    // Function to update the maximum transaction amount (anti-whale measure).
    // Takes the new max transaction amount as a percentage of total supply.
    // Adjusted arithmetic without SafeMath.
    function updateMaxTxAmount(uint256 _maxTxAmountPercentage) external onlyOwner {
         require(_maxTxAmountPercentage > 0 && _maxTxAmountPercentage <= 100, "Percentage must be between 1 and 100");
        _maxTxAmount = _totalSupply * _maxTxAmountPercentage / 100;
        emit MaxTxAmountUpdated(_maxTxAmount); // Emit event
    }

    // Function to exclude an address from paying fees.
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // Function to include an address in paying fees.
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // Emergency function to pause transfers (only by owner).
    function pause() external onlyOwner {
        _pause();
    }
    // Function to unpause transfers (only by owner).
    function unpause() external onlyOwner {
        _unpause();
    }

    // Note on withdrawMarketingFunds:
    // The previous function was removed. Funds sent to the marketingWallet (0xB987519efe0990dBa63A097a14EAF85308f2B380)
    // are managed directly from that external wallet. The contract does not control withdrawal from an external address.


    // --- View Functions (Public Getters) ---

    // Checks if the creator lock is currently active.
    function isCreatorLockActive() public view returns (bool) {
        // Lock is active if distribution has happened AND the current block timestamp is before the lock end time.
        // We check tokensAlreadyDistributed here as the lock time is set only after distribution.
        return tokensAlreadyDistributed && block.timestamp < creatorLockEndTime;
    }

     // Checks if a specific address is excluded from fees.
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    // Function to get the designated creator wallet address.
    function getCreatorWallet() public view returns (address) {
        return creatorWallet;
    }

     // Function to get the designated marketing wallet address.
    function getMarketingWallet() public view returns (address) {
        return marketingWallet;
    }

    // Function to get the timestamp when the creator lock ends.
     function getCreatorLockEndTime() public view returns (uint256) {
        return creatorLockEndTime;
    }

    // Function to get the maximum transaction amount allowed.
    function getMaxTxAmount() public view returns (uint256) {
        return _maxTxAmount;
    }

    // Function to check if the initial distribution has been performed.
    function getTokensAlreadyDistributed() public view returns (bool) {
        return tokensAlreadyDistributed;
    }

    // --- Migration V2 (Optional Future) ---
    // Function to set the address of the new V2 contract for migration.
    function setMigrationAddress(address _newContractAddress) external onlyOwner {
        require(_newContractAddress != address(0), "New contract address cannot be zero"); // Ensure valid address
        newContractAddress = _newContractAddress; // Set the new contract address
        migrationEnabled = true; // Enable migration flag
        emit MigrationInitiated(newContractAddress); // Emit event
    }

    // Placeholder for migration logic.
    // This function would be called by holders to migrate their tokens.
    // It needs to interact with the new V2 contract, which requires defining its interface (INewContract).
    /*
    // Example interface definition (needs to match your V2 contract)
    // interface INewContract { function mintV2Tokens(address recipient, uint256 amount) external returns (bool); }

    function migrateToV2(uint256 amount) public {
        require(migrationEnabled, "Migration is not enabled"); // Migration must be enabled by the owner
        require(balanceOf(msg.sender) >= amount, "Insufficient funds for migration"); // User must have enough tokens

        // Logic to transfer tokens to the new contract (effectively burning them in this contract)
        _transfer(msg.sender, newContractAddress, amount); // Transfer to the new contract address

        // Example of calling a function on the new V2 contract to issue V2 tokens
        // This part depends entirely on the V2 contract's design.
        // require(INewContract(newContractAddress).mintV2Tokens(msg.sender, amount), "V2 migration failed"); // Call a function on the V2 contract
    }
    */


    // --- Pausable Override ---
    // This function is called before every internal transfer (_transfer)
    // and ensures transfers are not allowed if the contract is paused.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount); // Call the base OpenZeppelin function
    }

   // Removed redundant getter functions for initial amounts as they are calculated internally in manualDistributeTokens.
}