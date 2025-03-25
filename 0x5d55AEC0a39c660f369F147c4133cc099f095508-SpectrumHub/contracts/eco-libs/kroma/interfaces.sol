// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IStandardBridge {
    function bridgeETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) external payable;

    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function bridgeETH(uint32 _minGasLimit, bytes calldata _extraData) external payable;

    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function finalizeBridgeETH(address _from, address _to, uint256 _amount, bytes calldata _extraData) external payable;

    function finalizeBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) external;

    receive() external payable;
}

interface IKromaBridge is IStandardBridge {}
