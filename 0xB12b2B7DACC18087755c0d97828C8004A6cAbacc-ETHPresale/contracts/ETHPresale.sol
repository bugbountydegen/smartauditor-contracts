// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ETHPresale is ReentrancyGuard, Ownable, Pausable {
    IERC20 public USDTInterface; // USDT on Ethereum Mainnet
    Aggregator public aggregatorInterface; // Chainlink on Ethereum Mainnet

    uint256 public currentStage;
    uint256 public currentPrice;
    uint256 public totalTokensSold;
    uint256 public constant DEFAULT_PRICE = 0.0021 * 1 ether;

    uint256 public usdtRaised;
    address public paymentWallet; // Actual
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userTokens;

    event TokensBoughtWithEth(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 ethPrice,
        uint256 tokenPrice,
        uint256 timestamp
    );

    event TokensBoughtWithWert(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 ethPrice,
        uint256 tokenPrice,
        uint256 timestamp
    );

    event TokensBoughtWithUsdt(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 tokenAmount,
        uint256 tokenPrice,
        uint256 timestamp
    );

    constructor(
        address _paymentWallet,
        address _usdt,
        address _aggregator
    ) Ownable(msg.sender) {
        // 0.0021 usdt first stage
        currentPrice = DEFAULT_PRICE;
        currentStage = 1;

        USDTInterface = IERC20(_usdt);
        paymentWallet = _paymentWallet;
        aggregatorInterface = Aggregator(_aggregator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function buyWithUSDT(
        uint256 usdtAmount
    ) external whenNotPaused returns (bool) {
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(
            usdtAmount <= ourAllowance,
            "Make sure to add enough allowance"
        );
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                paymentWallet,
                usdtAmount
            )
        );
        require(success, "Token payment failed");

        uint256 _tokenAmount = ((usdtAmount * 10 ** 12) / currentPrice) *
            1 ether;

        usdtRaised += usdtAmount * 10 ** 12;
        totalTokensSold += _tokenAmount;

        userDeposits[_msgSender()] += usdtAmount * 10 ** 12;
        userTokens[_msgSender()] += _tokenAmount;

        emit TokensBoughtWithUsdt(
            _msgSender(),
            usdtAmount,
            _tokenAmount,
            currentPrice,
            block.timestamp
        );
        return true;
    }

    function buyWithEth()
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(msg.value > 0, "No ETH sent");
        sendValue(payable(paymentWallet), msg.value);

        uint256 _ethAmount = msg.value;
        uint256 _ethPrice = getLatestEthPrice();

        uint256 _tokenAmount = (_ethAmount * _ethPrice) / currentPrice;

        usdtRaised += (_ethAmount * _ethPrice) / 1 ether;
        totalTokensSold += _tokenAmount;

        userDeposits[_msgSender()] += (_ethAmount * _ethPrice) / 1 ether;
        userTokens[_msgSender()] += _tokenAmount;

        emit TokensBoughtWithEth(
            _msgSender(),
            _ethAmount,
            _tokenAmount,
            _ethPrice,
            currentPrice,
            block.timestamp
        );

        return true;
    }

    function buyWithWert(
        address _user
    ) external payable whenNotPaused nonReentrant returns (bool) {
        require(msg.value > 0, "No ETH sent");
        sendValue(payable(paymentWallet), msg.value);

        uint256 _ethAmount = msg.value;
        uint256 _ethPrice = getLatestEthPrice();

        uint256 _tokenAmount = (_ethAmount * _ethPrice) / currentPrice;

        usdtRaised += (_ethAmount * _ethPrice) / 1 ether;
        totalTokensSold += _tokenAmount;

        userDeposits[_user] += (_ethAmount * _ethPrice) / 1 ether;
        userTokens[_user] += _tokenAmount;

        emit TokensBoughtWithWert(
            _user,
            _ethAmount,
            _tokenAmount,
            _ethPrice,
            currentPrice,
            block.timestamp
        );

        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function changePrice(uint256 _currentPrice) external onlyOwner {
        currentPrice = _currentPrice;
    }

    function changeStage(uint256 _stage) external onlyOwner {
        require(_stage > 0, "Invalid stage");

        uint256 price = DEFAULT_PRICE;
        for (uint256 i = 1; i < _stage; i++) {
            price = (price * 105) / 100;
        }

        currentStage = _stage;
        currentPrice = price;
    }

    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        paymentWallet = _newPaymentWallet;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function getCurrentStage() public view returns (uint256) {
        return currentStage;
    }

    function withdrawToken(
        address tokenContractAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenContractAddress);
        SafeERC20.safeTransfer(tokenContract, msg.sender, amount);
    }

    function withdrawNative(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
