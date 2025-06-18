// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}



//SPDX-License-Identifier:MIT
pragma solidity 0.8.24;




/// @title  Staking contract for Kibho

contract KibhoStaking is Ownable,ReentrancyGuard{

    // Kibho token
    IERC20 public kibhoToken;

    // Stake Amount for Each Package
    uint256[11] public stakeAmount;
    // Returns Percentage
    uint256[5] public kibhoReturns;
    // Level Income on ROI
    uint256[5] public levelIncome;
    // Stake Periods
    uint256[5] public stakePeriods;
    // Referral Commission
    uint256 public referralCommission;
    // Total Platform Investments
    uint256 public totalStakedAmount;
    // Total Users Count
    uint256 public totalUsers;
    // Total Rewards 
    uint256 public totalPlatformRewards;
    // minimum Withdrawal limit
    uint256 public minimumWithdrawal;
    bool public isEarlyStakeUnlock;
    uint256 public unstakeFee;

    struct Referral {
        address referrer;
        uint8 level;
    }

    struct StakingDetails{
        uint256 stakeId;
        uint8 packageType;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint8 timePeriodType;
        uint256 lastClaim;
    }

    struct userDetails{
        uint256 totalStakeAmount;
        uint256 totalClaimed;
        uint256 totalStakes;
        uint256 totalReferralAmount;
        uint256 referralCount;
        address[] referralUsers;
    }

    mapping(address => Referral[]) private referralChains;

    mapping(address => mapping(uint256 => StakingDetails)) public details;

    mapping(address => userDetails) public UserDetails;

    // User exists or not
    mapping(address => bool) public isUserExist;
    mapping(address => uint256) private userStakeIds;
    mapping(address => address) public getReferrer;

    mapping(address => uint256[]) private stakedIds;
    mapping(address => mapping(uint256 => bool)) public isUserClaimed;

     


    // kibho Staking all events
    event Stakekibho(address user, uint256 stakeId, uint256 amount, address referrer, uint8 packageType, uint256 stakeTime,uint256 referrerFee, uint256 lockTime, uint256 _returns);
    event ClaimRewards(address user, uint256 amount, uint256 stakeId, uint256 lastClaimTime);
    event ClaimReferral(address referrer, uint256 amount, uint8 level);
    event Unstake(address user, uint256 amount,uint256 stakeId);
    event SetStakeAmount(uint8 _package, uint256 amount);
    event SetResturnsPercent(uint8 _month, uint256 percent);
    event SetLevelIncome(uint8 level, uint256 percent);
    event SetReferralCommission(uint256 _commission);
    event WithdrawKibho(uint256 amount);
    event SetMinimumWtihdrawal(uint256 amount);
    event SetUnstakeFee(uint256 fee);
    event SetUnstakeStatus(bool _status);
    event SetTimeLock(uint8 packages, uint256 _time);




    constructor(address initialOwner, address tokenAddress) Ownable(initialOwner)
    {
      stakeAmount = [0,1000 ether,5000 ether,10000 ether,15000 ether,25000 ether,35000 ether,50000 ether,100000 ether,150000 ether,200000 ether];
      kibhoReturns = [0,30,35,40,50];
      levelIncome = [10,5,8,10,12];
      stakePeriods = [0, 90 days, 180 days, 270 days, 365 days];
      referralCommission = 3;
      kibhoToken = IERC20(tokenAddress);
      minimumWithdrawal = 100 ether;
      unstakeFee = 25;
    }

    // External Functions

    function stakeKibho(uint8 packageType,uint8 _lockTime,address referrer)external nonReentrant{
        require(isUserExist[referrer] || referrer == owner() || referrer == address(0) ,"Referrer Not Found");
        require(msg.sender != referrer ,"Own Referrals not Allowed");
        uint256 referralFee ;
        if(referrer != address(0)){
             referralFee = (stakeAmount[packageType] *referralCommission)/100;
             UserDetails[referrer].totalReferralAmount +=referralFee;
             UserDetails[referrer].referralCount++;
        }else{
            referralFee = 0;
        }
        uint256 id = userStakeIds[msg.sender]+1;
        userStakeIds[msg.sender]++;
        totalStakedAmount += stakeAmount[packageType];      
        UserDetails[msg.sender].totalStakeAmount +=stakeAmount[packageType];
        UserDetails[msg.sender].totalStakes++;

        if(!isUserExist[msg.sender]){
            if(referrer != address(0)){
            getReferrer[msg.sender] = referrer;
            UserDetails[referrer].referralUsers.push(msg.sender);
            updateReferrals(referrer);
            }
            totalUsers++;
        }else{
             require(referrer == getReferrer[msg.sender] || referrer == address(0),"Set Valid Referrer");
        }
        isUserExist[msg.sender] = true;
        stakedIds[msg.sender].push(id);
        StakingDetails storage _user = details[msg.sender][id];
        _user.stakeAmount = stakeAmount[packageType];
        _user.stakeId = id;
        _user.packageType = packageType;
        _user.stakeTime = block.timestamp;
        _user.timePeriodType = _lockTime;
        _user.lastClaim = block.timestamp;
        details[msg.sender][id] = _user;
        kibhoToken.transferFrom(msg.sender, address(this),stakeAmount[packageType] - referralFee);
        if(referralFee > 0)
            kibhoToken.transferFrom(msg.sender, referrer,referralFee);
        emit Stakekibho(msg.sender, id, stakeAmount[packageType], referrer, packageType, block.timestamp, referralFee, stakePeriods[_lockTime]/1 days,kibhoReturns[_lockTime]);
    }

    function updateReferrals(address referrer) internal{
        referralChains[msg.sender].push(Referral(referrer, 1));

        // Store up to 4 more levels of referrals
        address currentReferrer = referrer;
        for (uint8 i = 2; i <= 5; i++) {
            if (currentReferrer == address(0)) break;
            
            if (referralChains[currentReferrer].length > 0) {
                address upperReferrer = referralChains[currentReferrer][0].referrer;
                referralChains[msg.sender].push(Referral(upperReferrer, i));
                currentReferrer = upperReferrer;
            } else {
                break;
            }
        }
    }

    function getReferralChain(address user) external view returns (Referral[] memory) {
        return referralChains[user];
    }
    
    function getReturns(address user, uint256 Id)public view returns(uint amount){
        uint256 _stakeAmount = details[user][Id].stakeAmount;
        uint8 _lockTime = details[user][Id].timePeriodType;
        uint256 _days = stakePeriods[_lockTime]/ 1 days;
        uint256 returnPerDay = (_stakeAmount *kibhoReturns[_lockTime] / 1000)/_days;
        uint256 time;
        time = (block.timestamp - details[user][Id].lastClaim)/ 1 days;
        uint256 lockTime = details[user][Id].stakeTime + stakePeriods[_lockTime];

        if(block.timestamp >= lockTime){
            if(details[user][Id].lastClaim >= lockTime)
             time = 0;
            else
             time = (lockTime - details[user][Id].lastClaim)/1 days;

        }
        amount = returnPerDay * time ;
        if(time == 0){
            amount = 0;
        }
        
        return amount;
    }

    function getTotalRewards(address user) public view returns (uint256 totalRewards) {
        uint256[] memory ids = stakedIds[user];
        totalRewards = 0;
        
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = getReturns(user, id);
            totalRewards += amount;
        }
        
        return totalRewards;
   }

    function claimRewards(uint256 Id) public {
        uint256 _rewards = getReturns(msg.sender, Id);
        require(_rewards > 0,"No Enough Rewards");
        details[msg.sender][Id].lastClaim = block.timestamp;
        UserDetails[msg.sender].totalClaimed += _rewards;
        totalPlatformRewards += _rewards;
        uint256 remainingAmount = distributeLevelIncome(_rewards);
        kibhoToken.transfer(msg.sender,remainingAmount);
        emit ClaimRewards(msg.sender, remainingAmount, Id, block.timestamp);
    }

    function distributeLevelIncome(uint256 amount) internal returns(uint256 _amount) {
     require(amount > 0, "Amount must be greater than 0");

     Referral[] memory userReferrals = referralChains[msg.sender];
     uint256 remainingAmount = amount;

     for (uint8 i = 0; i < userReferrals.length && i < levelIncome.length; i++) {
        address referrer = userReferrals[i].referrer;
        uint256 percentage = levelIncome[i];
        uint256 referralAmount = 0;

        Referral[] memory referrerReferrals = referralChains[referrer];
        uint256 referrerReferralCount = referrerReferrals.length;
        if(referrer == owner())
               referrerReferralCount = 10;

        if (i == 0 && referrerReferralCount >= 1) {
            // Referrer receives level 1 income if they have at least 1 referral
            referralAmount = (amount * percentage) / 100;
        } else if (i >= 1 && i <= 2 && referrerReferralCount >= 2) {
            // Referrer receives level 2 and 3 income if they have at least 2 referrals
            referralAmount = (amount * percentage) / 100;
        } else if (i >= 3 && i <= 4 && referrerReferralCount >= 3) {
            // Referrer receives level 4 and 5 income if they have at least 3 referrals
            referralAmount = (amount * percentage) / 100;
        }

        if (referralAmount > 0 && referrer != address(0)) {
            // Transfer referral amount to the referrer
            kibhoToken.transfer(referrer, referralAmount);
            remainingAmount -= referralAmount;
            emit ClaimReferral(referrer, referralAmount, i);
        }
     }
      return remainingAmount;
    }

    function claimAllRewards() public nonReentrant{
        uint256 __rewards = getTotalRewards(msg.sender);
        require(__rewards >= minimumWithdrawal,"Not enough minimum withdrawal amount");
        uint256[] memory ids = stakedIds[msg.sender];
        require(ids.length > 0, "Must provide at least one ID");
        
        for (uint256 i = 0; i < ids.length; i++) {
            claimRewards(ids[i]);
        }
    }

    function getStakeIds(address user)external view returns(uint256[] memory){
        return stakedIds[user];
    }

    function unStake(uint256 Id) external nonReentrant {
        uint256 packageType = details[msg.sender][Id].timePeriodType;
        require(block.timestamp >= details[msg.sender][Id].stakeTime + stakePeriods[packageType]," Wait For LockTime to complete");
        uint256 _rewards = getReturns(msg.sender, Id);
        if(_rewards > 0){
            claimRewards(Id);
        }
        uint256 _stakeAmount = details[msg.sender][Id].stakeAmount;
        totalStakedAmount -= _stakeAmount;
        UserDetails[msg.sender].totalStakes--;
        UserDetails[msg.sender].totalStakeAmount -= _stakeAmount;
        delete details[msg.sender][Id];
        removeStakedId(Id);
        kibhoToken.transfer(msg.sender,_stakeAmount);
        emit Unstake(msg.sender,_stakeAmount,Id);
    }


    function unStakeEarly(uint256 Id) external nonReentrant{
        require(isEarlyStakeUnlock,"Early Stake Locked");
        uint256 _rewards = getReturns(msg.sender, Id);
        if(_rewards > 0){
            claimRewards(Id);
        }
        uint256 _stakeAmount = details[msg.sender][Id].stakeAmount;
        uint256 fee = _stakeAmount * unstakeFee / 100 ;
        totalStakedAmount -= _stakeAmount;
        UserDetails[msg.sender].totalStakes--;
        UserDetails[msg.sender].totalStakeAmount -= _stakeAmount;
        delete details[msg.sender][Id];
        removeStakedId(Id);
        kibhoToken.transfer(msg.sender,_stakeAmount-fee);
        kibhoToken.transfer(owner(),fee);
        emit Unstake(msg.sender,_stakeAmount,Id);
    }

    function setUnstakeFee(uint256 _fee)external onlyOwner{
        unstakeFee = _fee;
        emit SetUnstakeFee(_fee);
    }

    function setUnstakeStatus(bool _unlock)external onlyOwner{
        isEarlyStakeUnlock = _unlock;
        emit SetUnstakeStatus(_unlock);  
    }

    function removeStakedId(uint256 id) internal {
        uint256[] storage ids = stakedIds[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == id) {
                ids[i] = ids[ids.length - 1];  // Replace the found element with the last element
                ids.pop();  // Remove the last element
                break;
            }
        }
    }
   

    //Owner Functions

    /**
    * @notice Allows the contract owner to update the staking amount for a specific packageType.
    * @dev This function is restricted to the contract owner by the `onlyOwner` modifier.
    * The owner must provide the packageType number and the new staking amount.
    * @param packageType The packageType number for which the staking amount needs to be updated.
    * @param amount The new staking amount for the specified packageType.
    * Emits a {SetStakeAmount} event.
    */
    function setStakeAmount(uint8 packageType,uint256 amount)external onlyOwner{
        stakeAmount[packageType] = amount;
        emit SetStakeAmount(packageType,amount);
    }

    /**
    * @notice Allows the contract owner to update the staking return percentage for a specific lock period.
    * @dev This function is restricted to the contract owner by the `onlyOwner` modifier.
    * The owner must provide the month identifier (`_month`) to select the lock period and the new return percentage.
    * 
    * The `_month` parameter corresponds to the lock period as follows:
    * - 1: 3-month lock
    * - 2: 6-month lock
    * - 3: 9-month lock
    * - 4: 12-month lock
    *
    * @param _month The lock period identifier (1 for 3 months, 2 for 6 months, etc.).
    * @param percentage The new return percentage for the specified lock period.
    * Emits a {SetResturnsPercent} event.
    */
    function setResturnsPercent(uint8 _month, uint256 percentage) external onlyOwner{
        kibhoReturns[_month] = percentage;
        emit SetResturnsPercent(_month,percentage);
    }

    /**
    * @notice Allows the contract owner to update the income percentage for a specific level in the ROI system.
    * @dev This function is restricted to the contract owner by the `onlyOwner` modifier.
    * The owner must provide the level number and the new income percentage to update.
    * 
    * There are 5 levels, and the `level` parameter corresponds to the level number (0 to 4).
    *
    * @param level The level number for which the income percentage is being updated (0 to 4).
    * @param incomePercent The new income percentage for the specified level.
    * Emits a {SetLevelIncome} event.
    */
    function setLevelIncome(uint8 level, uint256 incomePercent) external onlyOwner{
        levelIncome[level] = incomePercent;
        emit SetLevelIncome(level, incomePercent);
    }

    /**
    * @notice Allows the contract owner to update the referral commission percentage.
    * @dev This function is restricted to the contract owner by the `onlyOwner` modifier.
    * The owner can set a new commission percentage for the referral system.
    *
    * @param _commission The new referral commission percentage to be set.
    * Emits a {SetReferralCommission} event.
    */
    function setReferralCommission (uint256 _commission) external onlyOwner{
        referralCommission = _commission;
        emit SetReferralCommission(_commission);
    }

    function withdrawKibho(uint256 amount)external onlyOwner{
        require(kibhoToken.balanceOf(address(this)) >= amount,"You do not have enough Kibho");
        kibhoToken.transfer(msg.sender,amount);
        emit WithdrawKibho(amount);
    }

    function setMinimumWtihdrawal(uint256 _amount)external onlyOwner{
        minimumWithdrawal = _amount;
        emit SetMinimumWtihdrawal(_amount);
    }

    function setTimeLock(uint8 _package,uint256 lockTime)external onlyOwner{
        stakePeriods[_package] = lockTime;
        emit SetTimeLock(_package,lockTime);
    }
}