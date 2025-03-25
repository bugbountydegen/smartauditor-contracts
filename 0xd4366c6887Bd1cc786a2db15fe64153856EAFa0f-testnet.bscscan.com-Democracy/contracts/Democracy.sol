// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Democracy is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    uint256 public lastMintOperation;
    uint256 private constant MINT_TIME_LOCK = 2 days;  

    function mintMonthly() external onlyOwner nonReentrant {
        

    require(block.timestamp >= nextMintEvent, "Too early to mint");
    require(block.timestamp >= lastMintTime + 1 days, "Minting too frequently");
    require(block.timestamp >= lastMintOperation + MINT_TIME_LOCK, "Operation locked");

    uint256 mintAmount = emissionRate * 30 days;
    require(mintAmount <= MAX_SUPPLY - totalSupply(), "Exceeds max supply limit");
    
    _mint(owner(), mintAmount);
    emit TokensMinted(mintAmount, owner());
    
    totalMinted = totalMinted + mintAmount;
    updateEmissionRate();
    nextMintEvent = nextMintEvent + 30 days;
    lastMintTime = block.timestamp;
    lastMintOperation = block.timestamp;
}

    function complexFunction(uint256 a, uint256 b) external {
        uint256 sum = a + b; 
    uint256 doubleA = a << 1; 
    uint256 doubleB = b << 1; 

        externalCall1(sum);        
        externalCall2(doubleA, doubleB); 
    } 

    function externalCall1(uint256 value) public {
        // Function logic goes here
    }

    function externalCall2(uint256 value1, uint256 value2) public {
        // Function logic goes here
    }
      
    uint256 constant MAX_INNER_ARRAY_LENGTH = 10; 

    mapping(address => bool) blacklists;

    function processTwoDimensionalArray(uint256[][] calldata inputArray) external pure {
    uint256 inputLength = inputArray.length;  // Cache the length of the input array
    require(inputLength <= MAX_ARRAY_LENGTH, "Array size exceeds limit");

    for (uint256 i = 0; i < inputLength; ++i) {  // Use pre-increment here
        uint256 innerLength = inputArray[i].length;  // Cache the length of the inner array
        require(innerLength <= MAX_INNER_ARRAY_LENGTH, "Inner size exceeds limit");      
    }
    
}
 
    uint256 private constant MAX_ARRAY_LENGTH = 50; 

    function processArrayData(uint256[] calldata inputData) external pure {
    require(inputData.length <= MAX_ARRAY_LENGTH, "Input array too large");
    
}

    uint256 private nextMintEvent;
    uint256 private emissionRate;
    uint256 private totalMinted;
    uint256 private lastMintTime;
    uint256 private constant MAX_SUPPLY = 36900000000 * 10**18;
    uint256 private constant DEVELOPER_ALLOCATION = 6000000000 * 10**18; 

    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function getTotalMinted() public view returns (uint256) {
        return totalMinted;
    }

    function getCirculatingSupply() public view returns (uint256) {
        
        return totalMinted - balanceOf(address(this));
    }

    event BlacklistUpdated(address indexed _address, bool _status);
    event RulesUpdated(bool _limited, address _uniswapV2Pair, uint256 _maxHolding, uint256 _minHolding);
    event TradingStarted(address _uniswapV2Pair);
    event TokensMinted(uint256 amount, address indexed to);

    function initialize(uint256 _totalSupply) public initializer {
        __ERC20_init("Democracy", "DEM");
        __Ownable_init(_msgSender());
        __ReentrancyGuard_init();

        _mint(_msgSender(), DEVELOPER_ALLOCATION);  
        _mint(address(this), _totalSupply - DEVELOPER_ALLOCATION);  

        nextMintEvent = block.timestamp + 30 days;
        emissionRate = 500;
        lastMintTime = block.timestamp;
    }
    
    function updateEmissionRate() private {
        emissionRate = emissionRate * 98 / 100;  
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
        emit BlacklistUpdated(_address, _isBlacklisting);
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        if (_limited) {
            require(_maxHoldingAmount != 0 && _minHoldingAmount < _maxHoldingAmount, "Invalid holding limits");
            maxHoldingAmount = _maxHoldingAmount;
            minHoldingAmount = _minHoldingAmount;
            uniswapV2Pair = _uniswapV2Pair;
            emit RulesUpdated(_limited, _uniswapV2Pair, _maxHoldingAmount, _minHoldingAmount);
        }
    }

    function startTrading() external onlyOwner {
        require(uniswapV2Pair != address(0), "UniswapV2 Pair not set");
        emit TradingStarted(uniswapV2Pair);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();  
        require(!blacklists[sender] && !blacklists[to], "Blacklisted address");

        if (uniswapV2Pair != address(0) && sender == uniswapV2Pair && to != owner()) {
            uint256 newBalance = balanceOf(to) + amount;
            require(newBalance <= maxHoldingAmount && newBalance >= minHoldingAmount, "Transfer violates holding limits");
        }

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(!blacklists[from] && !blacklists[to], "Blacklisted address");

        if (uniswapV2Pair != address(0) && from == uniswapV2Pair && to != owner()) {
            uint256 newBalance = balanceOf(to) + amount;
            require(newBalance <= maxHoldingAmount && newBalance >= minHoldingAmount, "Transfer violates holding limits");
        }

        return super.transferFrom(from, to, amount);
    }
}
