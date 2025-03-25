// SPDX-License-Identifier: MIT
/*
#########################################################
# ____    _    ____  _____ ____    _    ___    __   __  #
#| __ )  / \  / ___|| ____|  _ \  / \  |_ _|  / /___\ \ #
#|  _ \ / _ \ \___ \|  _| | | | |/ _ \  | |  / /_____\ \#
#| |_) / ___ \ ___) | |___| |_| / ___ \ | |  \ \_____/ /#
#|____/_/___\_\____/|_____|____/_/_  \_\___|  \_\   /_/ #
#| __ )|  _ \|_ _|  _ \ / ___| ____|                    #
#|  _ \| |_) || || | | | |  _|  _|                      #
#| |_) |  _ < | || |_| | |_| | |___                     #
#|____/|_| \_\___|____/ \____|_____|                    #
#########################################################   
# BRIDGE REWARDS - Bridge.sol - www.getbased.ai         #
#########################################################
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BasedAIBridge is ReentrancyGuard, Pausable {
    IERC20 public pepeCoin;
    IERC721 public brainNFT;
    address public owner;
    address public pepeCoinAddress;
    bool public mainnetLive;
    uint256 public startTime;

    struct Stake {
        address tokenAddress;
        uint256 amount;
        uint256 timestamp;
        uint256 rate;
        uint256[] brainIds;
    }

    struct TokenConfig {
        uint256 initialRate;
        uint256 rateIncreaseAmount;
        uint256 rateIncreaseInterval;
        bool isSupported;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public credits;
    mapping(address => bool) public hasStaked;
    mapping(address => uint256) public lastKnownCredits;
    address[] public stakers;
    mapping(address => TokenConfig) public tokenConfigs;
    mapping(address => uint256) public finalScores; 

    event Staked(address indexed user, address tokenAddress, uint256 amount, uint256 timestamp, uint256 rate);
    event BrainStaked(address indexed user, uint256 tokenId, uint256 timestamp, uint256 rate);
    event MainnetActivated();
    event Withdrawn(address indexed user, uint256 amount);
    event BrainWithdrawn(address indexed user, uint256 tokenId);
    event CreditsUpdated(address indexed user, uint256 credits);
    event FinalScoreRecorded(address indexed user, uint256 finalScore);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        pepeCoinAddress = 0xA9E8aCf069C58aEc8825542845Fd754e41a9489A;
        pepeCoin = IERC20(0xA9E8aCf069C58aEc8825542845Fd754e41a9489A);
        brainNFT = IERC721(0xA9E8aCf069C58aEc8825542845Fd754e41a9489A);
        owner = msg.sender;
        mainnetLive = false;
        startTime = block.timestamp;

        tokenConfigs[0xA9E8aCf069C58aEc8825542845Fd754e41a9489A] = TokenConfig({
            initialRate: 500,
            rateIncreaseAmount: 0,
            rateIncreaseInterval: 30 days,
            isSupported: true
        });
    }

    // For user with TFT Enforcer
    function getCurrentRate(address tokenAddress) public view returns (uint256) {
        TokenConfig storage config = tokenConfigs[tokenAddress];
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 periods = timeElapsed / config.rateIncreaseInterval;
        return config.initialRate + (config.rateIncreaseAmount * periods);
    }

    function setBasedBrainNFT(address tokenAddress) external onlyOwner {
        brainNFT = IERC721(tokenAddress);
    }

    function addOrUpdateToken(address tokenAddress, uint256 _initialRate, uint256 _rateIncreaseAmount, uint256 _rateIncreaseInterval) external onlyOwner {
        tokenConfigs[tokenAddress] = TokenConfig({
            initialRate: _initialRate, // 500 for Pepecoin, 5000 for Brain Specific Token, 5 for Brain Credits, 5800 for $BASED, 1000 for FHE-ORDERBOOK Brain Token
            rateIncreaseAmount: _rateIncreaseAmount,
            rateIncreaseInterval: _rateIncreaseInterval,
            isSupported: true
        });
    }

    function removeToken(address tokenAddress) external onlyOwner {
        tokenConfigs[tokenAddress].isSupported = false;
    }

    function stake(address tokenAddress, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(tokenConfigs[tokenAddress].isSupported, "Token is not supported for staking");
        require(!mainnetLive, "Mainnet is live!");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        uint256 currentRate = tokenConfigs[tokenAddress].initialRate;

        // Empty brain array
        uint256[] memory brainIds = new uint256[](0);
        
        // Recover all credits if in the first 30 days
        if (block.timestamp - startTime <= 30 days) {
            credits[msg.sender] += lastKnownCredits[msg.sender];
            lastKnownCredits[msg.sender] = 0;
        }
        
        _addStake(msg.sender, tokenAddress, _amount, brainIds, currentRate);
    }

    function _addStake(address _staker, address _tokenAddress, uint256 _amount, uint256[] memory _brainIds, uint256 _rate) private {
        if (!hasStaked[_staker]) {
            hasStaked[_staker] = true;
            stakers.push(_staker);
        }

        stakes[_staker].push(Stake({
            tokenAddress: _tokenAddress,
            amount: _amount,
            timestamp: block.timestamp,
            rate: _rate,
            brainIds: _brainIds
        }));
        emit Staked(_staker, _tokenAddress, _amount, block.timestamp, _rate);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != pepeCoinAddress, "Unable to remove prebriged PepeCoin");
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

    function recoverERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), owner, tokenId);
    }

    function stakeBrain(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(brainNFT.ownerOf(_tokenId) == msg.sender, "Not the owner of the Brain");
        require(!mainnetLive, "Mainnet is live!");
        brainNFT.transferFrom(msg.sender, address(this), _tokenId);
        uint256 currentRate = tokenConfigs[address(pepeCoin)].initialRate;

        uint256[] memory brainIds = new uint256[](1);
        brainIds[0] = _tokenId;

        _addStake(msg.sender, address(pepeCoin), 100000 * (10 ** 18), brainIds, currentRate);
        emit BrainStaked(msg.sender, _tokenId, block.timestamp, currentRate);
    }

    function withdraw() external whenNotPaused nonReentrant {
        uint256 totalStaked = 0;
        uint256 stakeCount = stakes[msg.sender].length;
        
        // make sure the users credits are calculated.
        if (block.timestamp - startTime <= 30 days) {
            // Store any previous credit balances
            lastKnownCredits[msg.sender] = credits[msg.sender];
            // Update the credit table to the latest
            updateCredits(msg.sender);
            // Combine the old and new updated credits
            lastKnownCredits[msg.sender] += credits[msg.sender];
        }

        for (uint i = stakeCount; i > 0; i--) {
            uint index = i - 1;
            Stake storage stake = stakes[msg.sender][index];
            totalStaked += stake.amount;

            // If it is a Brain they can only withdraw the Brain
            if (stake.brainIds.length == 0) {
                IERC20(stake.tokenAddress).transfer(msg.sender, stake.amount);
                emit Withdrawn(msg.sender, stake.amount);
            }
            
            // Transfer any Brain NFTs back to the user
            for (uint j = 0; j < stake.brainIds.length; j++) {
                brainNFT.transferFrom(address(this), msg.sender, stake.brainIds[j]);
                emit BrainWithdrawn(msg.sender, stake.brainIds[j]);
            }
            
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length - 1];
            stakes[msg.sender].pop();
        }

        require(totalStaked > 0, "Nothing to remove from BasedAI bridge");
        credits[msg.sender] = 0;

    }

    function triggerMainnetLive() external onlyOwner {
        mainnetLive = true;
        for (uint i = 0; i < stakers.length; i++) {
            finalScores[stakers[i]] = getCredits(stakers[i]) + credits[stakers[i]];
            finalScores[stakers[i]] += lastKnownCredits[stakers[i]];
            emit FinalScoreRecorded(stakers[i], finalScores[stakers[i]]);
        }
        emit MainnetActivated();
    }

    function getFinalScore(address staker) public view returns (uint256) {
        require(mainnetLive, "BasedAI Mainnet is not live yet");
        return finalScores[staker];
    }

    function getCredits(address staker) private view returns (uint256) {
        uint256 totalCredits = 0;
        for (uint i = 0; i < stakes[staker].length; i++) {
            totalCredits += calculateCredits(stakes[staker][i]);
        }
        return totalCredits;
    }

    function updateCredits(address staker) private {
        uint256 totalCredits = 0;
        for (uint i = 0; i < stakes[staker].length; i++) {
            totalCredits += calculateCredits(stakes[staker][i]);
        }
        credits[staker] = totalCredits;
    }

    function calculateCredits(Stake memory stake) private view returns (uint256) {
        uint256 durationInSeconds = block.timestamp - stake.timestamp;
        uint256 accruedCredits = (stake.amount / stake.rate) * durationInSeconds / 86400; 
        return accruedCredits;
    }

    function calculateTotalCredits(address staker) public view returns (uint256) {
        if (mainnetLive) return finalScores[staker];
        uint256 totalCredits = 0;
        for (uint i = 0; i < stakes[staker].length; i++) {
            totalCredits += calculateCredits(stakes[staker][i]);
        }
        // add any leftover credits collected if they participated in Brain burn or Brain credits
        totalCredits += lastKnownCredits[staker];
        totalCredits += credits[staker];
        return totalCredits;
    }

    // Credits the user recovers if they restake. 
    function calculateReturnCredits(address staker) public view returns (uint256) {
        if (mainnetLive) return finalScores[staker];
        return lastKnownCredits[staker];
    }

    // calculates from a current stake how much a user has earned 
    function calculateCreditsPerToken(address staker, address _tokenAddress) public view returns (uint256) {
        require(!mainnetLive, "Mainnet is live, claim all rewards.");
        uint256 totalCredits = 0;
        for (uint i = 0; i < stakes[staker].length; i++) {
            if (stakes[staker][i].tokenAddress == _tokenAddress) {
                totalCredits += calculateCredits(stakes[staker][i]);
            }
        }
        return totalCredits;
    }

    function setCreditsForAddress(address _user, uint256 _credits) external onlyOwner {
        credits[_user] = _credits;
        emit CreditsUpdated(_user, _credits);
    }

    function getStakedAmount(address user, address tokenAddress) public view returns (uint256) {
        uint256 totalStaked = 0;
        for (uint i = 0; i < stakes[user].length; i++) {
            if (stakes[user][i].tokenAddress == tokenAddress) {
                totalStaked += stakes[user][i].amount;
            }
        }
        return totalStaked;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}


