// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";


contract AirPuffLendingUSDCe is ERC4626Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using MathUpgradeable for uint256;

    address public USDCe; // USDCe
    address public LendingVault; // Lending Vault address
    address public feeReceiver;
    uint256 public withdrawalFees;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public AirPuff_DEFAULT_PRICE;
    uint256 private totalUSDCe;
    uint256 public totalDebt;
    uint256 public utilRate;

    mapping(address => uint256) public userTimelock;
    mapping(address => bool) public allowedToGift;
    uint256 public lockTime;
    uint256[50] private __gaps;

    mapping(address => bool) public allowedStrategies;
    mapping(address => uint256) public strategyCap;
    mapping(address => uint256) public strategyBorrowedAmount;

    modifier onlyLendingVault() {
        require(allowedStrategies[msg.sender], "Not an allowed strategy");
        _;
    }

    modifier onlyUSDCeGifter() {
        require(allowedToGift[msg.sender], 'Not allowed to increment USDCe');
        _;
    }

    modifier zeroAddress(address addr) {
        require(addr != address(0), "ZERO_ADDRESS");
        _;
    }

    modifier noZeroValues(uint256 assetsOrShares) {
        require(assetsOrShares > 0, "VALUE_0");
        _;
    }

    event ProtocolFeeParamsSet(address newFeeReceiver, uint256 newWithdrawalFee);
    event LockTimeChanged(uint256 lockTime);

    event LendingVaultChanged(address newLendingVault);
    event Lend(address indexed user, uint256 amount);
    event RepayDebt(address indexed user, uint256 debtAmount, uint256 amountPaid);
    event USDCeGifterAllowed(address indexed gifter, bool status);
    event UtilRateChanged(uint256 utilRate);
    event Deposited(address caller, address receiver, uint256 assets, uint256 shares, uint256 timestamp, uint256 utilRate);
    event Withdrawn(address caller, address receiver, address owner, uint256 assets, uint256 shares, uint256 timestamp, uint256 utilRate);
    event AllowedStrategy(address strategy, bool status);
    event StrategyCapSet(address strategy, uint256 cap);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _USDCe) external initializer {
        require(_USDCe != address(0), "ZERO_ADDRESS");
        USDCe = _USDCe;
        AirPuff_DEFAULT_PRICE = 1e18;
        feeReceiver = msg.sender;
        lockTime = 0;
        allowedToGift[msg.sender] = true;

        __Ownable_init();
        __ERC4626_init(IERC20Upgradeable(_USDCe));
        __ERC20_init("USDCe-AirPuff", "USDCe-AirPuff");
    }

    /** ---------------- View functions --------------- */

    function balanceOfUSDCe() public view returns (uint256) {
        return totalUSDCe;
    }

    function getUtilizationRate() public view returns (uint256) {
        uint256 totalAirPuffDebt = totalDebt;
        return totalAirPuffDebt == 0 ? 0 : totalAirPuffDebt.mulDiv(1e18, totalUSDCe + totalAirPuffDebt);
    }

    /**
     * @notice Public function to get the current price of the AirPuff token.
     * @dev The function calculates the current price of the AirPuff token based on the total assets in the contract and the total supply of AirPuff tokens.
     * @return The current price of the AirPuff token.
     */
    function getAirPuffPrice() public view returns (uint256) {
        uint256 currentPrice;
        if (totalAssets() == 0) {
            currentPrice = AirPuff_DEFAULT_PRICE;
        } else {
            currentPrice = totalAssets().mulDiv(AirPuff_DEFAULT_PRICE, totalSupply());
        }
        return currentPrice;
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return totalUSDCe + totalDebt;
    }

    /** ----------- Change onlyOwner functions ------------- */

    function dummy() public {
        uint256 test;
    }

    function setAllowedStrategy(address _strategy, bool _status) external onlyOwner zeroAddress(_strategy) {
        allowedStrategies[_strategy] = _status;
        emit AllowedStrategy(_strategy, _status);
    }

    function setUtilRate(uint256 _utilRate) public onlyOwner {
        require(_utilRate <= 1e18, "Invalid utilization rate");
        utilRate = _utilRate;
        emit UtilRateChanged(_utilRate);
    }

    function allowUSDCeGifter(address _gifter,bool _status) external onlyOwner zeroAddress(_gifter) {
        allowedToGift[_gifter] = _status;
        emit USDCeGifterAllowed(_gifter, _status);
    }

    function setStrategyCap(address _strategy, uint256 _cap) external onlyOwner zeroAddress(_strategy) {
        require(_cap > 0, "Invalid cap");
        strategyCap[_strategy] = _cap;
        emit StrategyCapSet(_strategy, _cap);
    }

    function setProtocolFeesParams(
        address _feeReceiver,
        uint256 _withdrawalFees
    ) external onlyOwner zeroAddress(_feeReceiver) {
        require(_withdrawalFees <= DENOMINATOR, "Invalid withdrawal fees");
        withdrawalFees = _withdrawalFees;
        feeReceiver = _feeReceiver;
        emit ProtocolFeeParamsSet(_feeReceiver, _withdrawalFees);
    }

    function setLockTime(uint256 _lockTime) public onlyOwner {
        require(_lockTime < 7 days, "Invalid lock time");
        lockTime = _lockTime;
        emit LockTimeChanged(_lockTime);
    }

    /**
    * @notice Allow the Lending Vault to lend a certain amount of USDCe to the protocol.
    * @dev The function allows the Lending Vault to lend a certain amount of USDCe to the protocol. It updates the total debt and total USDCe balances accordingly.
    * @param _borrowed The amount of USDCe to lend.
    * @return status A boolean indicating the success of the lending operation.
    */
    function lend(uint256 _borrowed, address _receiver) external onlyLendingVault returns (bool status) {
        require(totalUSDCe > _borrowed, "Not enough USDCe to lend");
        require(strategyBorrowedAmount[msg.sender] + _borrowed <= strategyCap[msg.sender], "Borrow cap reached");

        strategyBorrowedAmount[msg.sender] += _borrowed;
        totalDebt = totalDebt + _borrowed;
        totalUSDCe -= _borrowed;

        require(getUtilizationRate() <= utilRate, "Leverage ratio too high");
        IERC20(USDCe).safeTransfer(_receiver, _borrowed);
        emit Lend(_receiver, _borrowed);
        return true;
    }

    /**
     * @notice Allows the Lending Vault to repay debt to the protocol.
     * @dev The function allows the Lending Vault to repay a certain amount of debt to the protocol. It updates the total debt and total USDCe balances accordingly.
     * @param _debtAmount The amount of debt to repay.
     * @param _amountPaid The amount of USDCe paid to repay the debt.
     * @return A boolean indicating the success of the debt repayment operation.
     */
    function repayDebt(uint256 _debtAmount, uint256 _amountPaid) external onlyLendingVault returns (bool) {
        IERC20(USDCe).safeTransferFrom(msg.sender, address(this), _amountPaid);
        totalDebt = totalDebt - _debtAmount;
        totalUSDCe += _amountPaid;
        strategyBorrowedAmount[msg.sender] -= _debtAmount;
        
        emit RepayDebt(msg.sender, _debtAmount, _amountPaid);
        return true;
    }   

    /**
     * @notice Deposit assets into the contract for a receiver and receive corresponding shares.
     * @dev The function allows a user to deposit a certain amount of assets into the contract and receive the corresponding shares in return.
     *      It noZeroValues if the deposited assets do not exceed the maximum allowed deposit for the receiver.
     *      It then calculates the amount of shares to be issued to the user and calls the internal `_deposit` function to perform the actual deposit.
     *      It updates the total USDCe balance and sets a timelock for the receiver.
     * @param _assets The amount of assets to deposit.
     * @param _receiver The address of the receiver who will receive the corresponding shares.
     * @return The amount of shares issued to the user.
     */
    function deposit(uint256 _assets, address _receiver) public override noZeroValues(_assets) returns (uint256) {
        require(_assets <= maxDeposit(msg.sender), "ERC4626: deposit more than max");

        uint256 UR = getUtilizationRate();
        uint256 shares;
        if (totalSupply() == 0) {
            require(_assets > 1000, "Not Enough Shares for first mint");
            uint256 SCALE = 10 ** decimals() / 10 ** 6;
            shares = (_assets - 1000) * SCALE;
            // uint256 toAsset = 
            _mint(address(this), 1000 * SCALE);
        } else {
            shares = previewDeposit(_assets);
        }

        _deposit(_msgSender(), msg.sender, _assets, shares);
        totalUSDCe += _assets;

        emit Deposited(msg.sender, _receiver, _assets, shares, block.timestamp,UR);
        return shares;
    }

    /**
     * @notice Withdraw assets from the contract for a receiver and return the corresponding shares.
     * @dev The function allows a user to withdraw a certain amount of assets from the contract and returns the corresponding shares.
     *      It noZeroValues if the withdrawn assets do not exceed the maximum allowed withdrawal for the owner.
     *      It also noZeroValues if there are sufficient assets in the vault to cover the withdrawal and if the user's withdrawal is not timelocked.
     *      It calculates the amount of shares to be returned to the user and calculates the withdrawal fee. It then transfers the fee amount to the fee receiver.
     *      The function then performs the actual withdrawal by calling the internal `_withdraw` function. It updates the total USDCe balance after the withdrawal and returns the amount of shares returned to the user.
     * @param _assets The amount of assets (USDCe) to withdraw.
     * @param _receiver The address of the receiver who will receive the corresponding shares.
     * @param _owner The address of the owner who is making the withdrawal.
     * @return The amount of shares returned to the user.
     */
    function withdraw(
        uint256 _assets, // Native (USDCe) token amount
        address _receiver,
        address _owner
    ) public override noZeroValues(_assets) returns (uint256) {
        require(_assets <= maxWithdraw(msg.sender), "ERC4626: withdraw more than max");
        require(balanceOfUSDCe() > _assets, "Insufficient balance in vault");

        uint256 UR = getUtilizationRate();
        uint256 shares = previewWithdraw(_assets);
        uint256 feeAmount = (_assets * withdrawalFees) / DENOMINATOR;
        IERC20(USDCe).safeTransfer(feeReceiver, feeAmount);

        uint256 userAmount = _assets - feeAmount;

        _withdraw(_msgSender(), msg.sender, msg.sender, userAmount, shares);
        totalUSDCe -= _assets;

        emit Withdrawn(msg.sender, _receiver, _owner, _assets, shares,block.timestamp,UR);
        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        revert("Not used");
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        revert("Not used");
    }

    //function that only allows a whitelisted address to call to increase totalUSDCe 
    function increaseTotalUSDCe(uint256 _amount) external onlyUSDCeGifter {
        IERC20(USDCe).safeTransferFrom(msg.sender, address(this), _amount);
        totalUSDCe += _amount;
    }
    
}
