// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IChainZoomVault {
    function withdraw(uint256 _amount, address _user, address _token) external;

    function deposit(uint256 _amount, address _user, address _token) external;

    function depositETH() external payable;

    function getBalance(address _token) external view returns (uint256);

    function swapETHForTokens(
        uint256 _ethAmount,
        address _tokenOut,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256);
}
