// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Democracy is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    

    uint256 public constant MAX_INNER_ARRAY_LENGTH = 10; 

    mapping(address => bool) public blacklists;

    function processTwoDimensionalArray(uint256[][] calldata inputArray) external pure {
    require(inputArray.length <= MAX_ARRAY_LENGTH, "Outer array exceeds maximum allowed length");

    for (uint256 i = 0; i < inputArray.length; i++) {
        require(inputArray[i].length <= MAX_INNER_ARRAY_LENGTH, "Inner array exceeds maximum allowed length");
        // Aqui você poderia adicionar lógica adicional para processar cada inner array
    }
}

function complexFunction(uint256 a, uint256 b) external {
    uint256 sum = a + b;       
    uint256 doubleA = a * 2;   
    uint256 doubleB = b * 2;   

    externalCall1(sum);        
    externalCall2(doubleA, doubleB);  
}

    function externalCall1(uint256 value) public {
        
    }

    function externalCall2(uint256 value1, uint256 value2) public {
        
    }

    uint256 public constant MAX_ARRAY_LENGTH = 50; 

    function processArrayData(uint256[] calldata inputData) external pure {
    require(inputData.length <= MAX_ARRAY_LENGTH, "Input array too large");
    
}

    uint256 public nextMintEvent;
    uint256 public emissionRate;
    uint256 public totalMinted;
    uint256 public lastMintTime;
    uint256 public constant MAX_SUPPLY = 36900000000 * 10**18;
    uint256 public constant DEVELOPER_ALLOCATION = 6000000000 * 10**18; 

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

    function mintMonthly() external onlyOwner nonReentrant {
        require(block.timestamp >= nextMintEvent, "Too early to mint");
        require(block.timestamp >= lastMintTime + 1 days, "Minting too frequently");
        
        uint256 mintAmount = emissionRate * 30 days;
        require(mintAmount <= MAX_SUPPLY - totalSupply(), "Exceeds max supply limit");
        
        _mint(owner(), mintAmount);
        emit TokensMinted(mintAmount, owner());
        
        totalMinted += mintAmount;
        updateEmissionRate();
        nextMintEvent += 30 days;
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
            require(_maxHoldingAmount > 0 && _minHoldingAmount < _maxHoldingAmount, "Invalid holding limits");
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
