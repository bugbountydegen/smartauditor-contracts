// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IChainZoomVault.sol";

contract ChainZoomVault is IChainZoomVault, Ownable {
    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable WETH;

    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event Deposit(address indexed token, address indexed user, uint256 amount);
    event AdminAdded(address indexed account, bool isAdmin);
    event OwnerWithdraw(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor() Ownable(_msgSender()) {
        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapRouter.WETH();
        // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[_msgSender()], "ChainZoomVault: only admin");
        _;
    }

    function getBalance(address _token) external view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    function withdraw(
        uint256 _amount,
        address _user,
        address _token
    ) external override onlyAdmin {
        if (_token == address(0)) {
            payable(_user).transfer(_amount);
        } else {
            IERC20(_token).transfer(_user, _amount);
        }

        emit Withdraw(_token, _user, _amount);
    }

    function deposit(
        uint256 _amount,
        address _user,
        address _token
    ) external override onlyAdmin {
        IERC20(_token).transferFrom(_user, address(this), _amount);
        emit Deposit(_token, _user, _amount);
    }

    function depositETH() external payable onlyAdmin {
        // This function accepts ETH deposits
        // The deposited ETH is automatically added to the contract's balance
    }

    function addAdmin(address _address, bool _isAdmin) external onlyOwner {
        admins[_address] = _isAdmin;
        emit AdminAdded(_address, _isAdmin);
    }

    function ownerWithdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(0)) {
            require(
                _amount <= address(this).balance,
                "ChainZoomVault: Insufficient ETH balance"
            );
            payable(_to).transfer(_amount);
        } else {
            require(
                _amount <= IERC20(_token).balanceOf(address(this)),
                "ChainZoomVault: Insufficient token balance"
            );
            IERC20(_token).transfer(_to, _amount);
        }

        emit OwnerWithdraw(_token, _to, _amount);
    }

    function swapETHForTokens(
        uint256 _ethAmount,
        address _tokenOut,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline
    ) external onlyAdmin returns (uint256) {
        require(
            _ethAmount <= address(this).balance,
            "ChainZoomVault: Insufficient ETH balance"
        );

        return
            _swapETHForTokens(
                _ethAmount,
                _tokenOut,
                _amountOutMin,
                _to,
                _deadline
            );
    }

    function _swapETHForTokens(
        uint256 _ethAmount,
        address _tokenOut,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenOut;

        // uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
        //     value: _ethAmount
        // }(_amountOutMin, path, _to, _deadline);

        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: _ethAmount
        }(_amountOutMin, path, _to, _deadline);

        return amounts[amounts.length - 1];
    }
}
