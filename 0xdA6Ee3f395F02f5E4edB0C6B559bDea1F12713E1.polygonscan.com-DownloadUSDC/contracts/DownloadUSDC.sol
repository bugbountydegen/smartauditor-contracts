/**
 *Submitted for verification at polygonscan.com on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DownloadUSDC is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant minUSDC = 20 * 1e6;
    uint256 public constant maxUSDC = 20000 * 1e6;

    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private devAddr = 0x21cC189e0c56F5388Cbd0cE3b67b618808eF4178;
    uint256 public feeRate = 4;
    uint256 public totalDeposits;
    uint256 public startTime;
    bool private init;

    struct User {
        uint256 deposits;
        uint256 withdraws;
        uint256 withdrawsRef;
        uint256 lastTime;
        uint256 refLastTime;
        address referrer;
        uint256 referrerDeposits;
        uint256 bonus;
    }

    mapping (address => User) public users;

    event deposited(address _user, address _refAddr, uint256 _amount, uint256 _refBonus);
    event withdrawn(address _user, uint256 _amount);
    event withdrawnRef(address _user, uint256 _amount);
    event compounded(address _user, uint256 _amount);
    event started(bool _init);

    constructor() {}

    /**
     * deposit
     * @dev deposit USDC fund with referral address
     **/
    function deposit(address refAddr, uint256 amount) public nonReentrant {
        require(init, "Err: Not started yet");
        require(amount >= minUSDC, "Err: should greater than 20");

        IERC20(usdc).transferFrom(address(msg.sender), address(this), amount);
        uint256 fee = calculateFee(amount);
        IERC20(usdc).transfer(devAddr, fee);

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount).sub(fee);
        require(users[msg.sender].deposits <= maxUSDC, "Err: shouldn't greater than 20000");

        users[msg.sender].lastTime = block.timestamp;

        if (refAddr != address(0) && refAddr != msg.sender) {
            users[msg.sender].referrer = refAddr;
        } else {
            users[msg.sender].referrer = devAddr;
        }
    
        uint256 referralBonus = amount.sub(fee).mul(28).div(100);  // 28% total referral bonus
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].refLastTime = block.timestamp;
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount).sub(fee);

        totalDeposits = totalDeposits.add(amount).sub(fee);
        emit deposited(msg.sender, users[msg.sender].referrer, amount.sub(fee), referralBonus);
    }

    /**
     * withdraw
     * @dev withdraw USDC as reward
     **/
    function withdraw() public nonReentrant {
        checkState();

        require(users[msg.sender].withdraws < users[msg.sender].deposits.mul(420).div(100), "Err: shouldn't withdraw more than 420%");

        uint256 amount = getRewardsSinceLastDeposit(msg.sender);
        require(amount > 0, "Err: zero amount");
        require(amount < getBalance(), "Err: shouldn't greater than contract balance");
        
        uint256 fee = calculateFee(amount);
        IERC20(usdc).transfer(devAddr, fee);
        users[msg.sender].withdraws = users[msg.sender].withdraws.add(amount);

        users[msg.sender].lastTime = block.timestamp;
        IERC20(usdc).transfer(address(msg.sender), amount.sub(fee));

        emit withdrawn(msg.sender, amount.sub(fee));
    }

    /**
     * withdrawRef
     * @dev withdraw USDC as referral bonus
     **/
    function withdrawRef() public nonReentrant {
        checkRefState();

        require(users[msg.sender].withdrawsRef < users[msg.sender].bonus, "Err: shouldn't withdrawRef more than 28% referral bonus");
        
        uint256 RefAmount = getBonusSinceLastWithdrawRef(msg.sender);
        require(RefAmount > 0, "Err: zero amount");
        require(RefAmount < getBalance(), "Err: shouldn't greater than contract balance");

        users[msg.sender].withdrawsRef = users[msg.sender].withdrawsRef.add(RefAmount);
        IERC20(usdc).transfer(address(msg.sender), RefAmount);
        users[msg.sender].refLastTime = block.timestamp;

        emit withdrawnRef(msg.sender, RefAmount);
    }

    /**
     * compound
     * @dev redeposit USDC fund earned as reward
     **/
    function compound() public nonReentrant {
        require(init, "Err: Not started yet");
        require(users[msg.sender].lastTime > 0, "Err: no deposit");
        
        uint256 amount = getRewardsSinceLastDeposit(msg.sender);
        require(amount > 0, "Err: zero amount");
        uint256 fee = calculateFee(amount);
        require(fee < getBalance(), "Err: shouldn't greater than contract balance");

        IERC20(usdc).transfer(devAddr, fee);
        users[msg.sender].deposits = users[msg.sender].deposits.add(amount).sub(fee);

        require(users[msg.sender].deposits <= maxUSDC, "Err: shouldn't greater than 20000");
        users[msg.sender].lastTime = block.timestamp;
        
        totalDeposits = totalDeposits.add(amount).sub(fee);
        emit compounded(msg.sender, amount.sub(fee));
    }

    function start(bool _start) public onlyOwner {
        init = _start;
        startTime = block.timestamp;
        
        emit started(init);
    }

    function setDevAddr(address _devAddr) public onlyOwner {
        require(_devAddr != address(0), "Err: can't be null");
        devAddr = _devAddr;
    }

    // view functions

    function checkState() internal view {
        require(init, "Err: Not started yet");
        require(users[msg.sender].lastTime > 0, "Err: no deposit");
        require(users[msg.sender].lastTime.add(7 days) < block.timestamp, "Err: not in time");
    }

    function checkRefState() internal view {
        require(init, "Err: Not started yet");
        require(users[msg.sender].refLastTime > 0, "Err: no deposit");
        require(users[msg.sender].refLastTime.add(7 days) < block.timestamp, "Err: not in time");
    }
    
    function calculateFee(uint256 amount) private view returns(uint256) {
        return amount.mul(feeRate).div(100);
    }
    
    function getBalance() public view returns(uint256) {
        return IERC20(usdc).balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }

    function getTotalWithdraws() public view returns(uint256) {
        return totalDeposits.sub(getBalance());
    }

    function getRewardsSinceLastDeposit(address addr) public view returns(uint256) {
        require(addr != address(0), "Err: can't be null");
        uint256 secondsPassed = min(604800, block.timestamp.sub(users[addr].lastTime));
        return secondsPassed.mul(users[addr].deposits).div(1728000);  // 35% weekly reward
    }

    function getBonusSinceLastWithdrawRef(address addr) public view returns(uint256) {
        require(addr != address(0), "Err: can't be null");
        uint256 secondsPassed = min(604800, block.timestamp.sub(users[addr].refLastTime));
        return secondsPassed.mul(users[addr].bonus).div(2419200);  // 7% weekly bonus
    }

    // pure functions
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? b : a;
    }
}