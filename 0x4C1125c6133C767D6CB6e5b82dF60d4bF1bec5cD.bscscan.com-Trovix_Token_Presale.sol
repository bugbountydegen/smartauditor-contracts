//SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Trovix_Token_Presale {
    IERC20 public token;
    IERC20 public USDT;

    uint256 public totalTokensSold;
    uint256 public totalUSDTCollected;
    uint256 public tokensPerUSDT;

    mapping(address => uint256) public userPurchasedTokens;

    address public perSaleOwner;

    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _owner,
        uint256 _tokensPerUSDT
    ) {
        token = IERC20(_tokenAddress);
        USDT = IERC20(_usdtAddress);
        perSaleOwner = _owner;
        tokensPerUSDT = _tokensPerUSDT;
    }

    modifier onlyOwner() {
        require(
            msg.sender == perSaleOwner,
            "ONLY_OWNER_CAN_ACCESS_THIS_FUNCTION"
        );
        _;
    }

    function updateUSDTAddress(address newUSDTAddress) public onlyOwner {
        USDT = IERC20(newUSDTAddress);
    }

    function updateTokenAddress(address newTokenAddress) public onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function updatePresaleOwner(address newTPresaleOwner) public onlyOwner {
        perSaleOwner = newTPresaleOwner;
    }

    function updateRate(uint256 newTokensPerUSDT) public onlyOwner {
        tokensPerUSDT = newTokensPerUSDT;
    }

    function endPreSale() public onlyOwner {
        uint256 contractTokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, contractTokenBalance);
    }

    function buyWithUSDT(uint256 _USDTAmount) public {
        uint256 tokenAmount = (_USDTAmount * tokensPerUSDT) / 10000;
       
        USDT.transferFrom(msg.sender, perSaleOwner, _USDTAmount);

        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "INSUFFICIENT_BALANCE_IN_CONTRACT"
        );

        bool sent = token.transfer(msg.sender, tokenAmount);
        require(sent, "FAILED_TO_TRANSFER_TOKENS_TO_BUYER");

        // Update totals
        userPurchasedTokens[msg.sender] += tokenAmount;
        totalTokensSold += tokenAmount;
        totalUSDTCollected += _USDTAmount;
    }

    function recoverTokens(address tokenToRecover) public onlyOwner {
        IERC20 tokenContract = IERC20(tokenToRecover);
        uint256 contractTokenBalance = tokenContract.balanceOf(address(this));
        require(contractTokenBalance > 0, "No tokens to recover");

        bool sent = tokenContract.transfer(msg.sender, contractTokenBalance);
        require(sent, "Failed to recover tokens");
    }
}