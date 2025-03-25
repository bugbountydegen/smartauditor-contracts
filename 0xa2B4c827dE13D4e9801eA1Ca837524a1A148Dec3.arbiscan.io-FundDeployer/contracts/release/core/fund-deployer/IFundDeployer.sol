// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <council@enzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title IFundDeployer Interface
/// @author Enzyme Council <security@enzyme.finance>
interface IFundDeployer {
    struct ReconfigurationRequest {
        address nextComptrollerProxy;
        uint256 executableTimestamp;
    }

    function cancelMigration(address _vaultProxy, bool _bypassPrevReleaseFailure) external;

    function cancelReconfiguration(address _vaultProxy) external;

    function createMigrationRequest(
        address _vaultProxy,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData,
        bool _bypassPrevReleaseFailure
    ) external returns (address comptrollerProxy_);

    function createNewFund(
        address _fundOwner,
        string calldata _fundName,
        string calldata _fundSymbol,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external returns (address comptrollerProxy_, address vaultProxy_);

    function createReconfigurationRequest(
        address _vaultProxy,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external returns (address comptrollerProxy_);

    function deregisterBuySharesOnBehalfCallers(address[] calldata _callers) external;

    function deregisterVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external;

    function executeMigration(address _vaultProxy, bool _bypassPrevReleaseFailure) external;

    function executeReconfiguration(address _vaultProxy) external;

    function getComptrollerLib() external view returns (address comptrollerLib_);

    function getCreator() external view returns (address creator_);

    function getDispatcher() external view returns (address dispatcher_);

    function getGasLimitsForDestructCall()
        external
        view
        returns (uint256 deactivateFeeManagerGasLimit_, uint256 payProtocolFeeGasLimit_);

    function getOwner() external view returns (address owner_);

    function getProtocolFeeTracker() external view returns (address protocolFeeTracker_);

    function getReconfigurationRequestForVaultProxy(address _vaultProxy)
        external
        view
        returns (ReconfigurationRequest memory reconfigurationRequest_);

    function getReconfigurationTimelock() external view returns (uint256 reconfigurationTimelock_);

    function getVaultLib() external view returns (address vaultLib_);

    function hasReconfigurationRequest(address _vaultProxy) external view returns (bool hasReconfigurationRequest_);

    function isAllowedBuySharesOnBehalfCaller(address _who) external view returns (bool isAllowed_);

    function isAllowedVaultCall(address _contract, bytes4 _selector, bytes32 _dataHash)
        external
        view
        returns (bool isAllowed_);

    function isRegisteredVaultCall(address _contract, bytes4 _selector, bytes32 _dataHash)
        external
        view
        returns (bool isRegistered_);

    function registerBuySharesOnBehalfCallers(address[] calldata _callers) external;

    function registerVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external;

    function releaseIsLive() external view returns (bool isLive_);

    function setComptrollerLib(address _comptrollerLib) external;

    function setGasLimitsForDestructCall(uint32 _nextDeactivateFeeManagerGasLimit, uint32 _nextPayProtocolFeeGasLimit)
        external;

    function setProtocolFeeTracker(address _protocolFeeTracker) external;

    function setReconfigurationTimelock(uint256 _nextTimelock) external;

    function setReleaseLive() external;

    function setVaultLib(address _vaultLib) external;
}
