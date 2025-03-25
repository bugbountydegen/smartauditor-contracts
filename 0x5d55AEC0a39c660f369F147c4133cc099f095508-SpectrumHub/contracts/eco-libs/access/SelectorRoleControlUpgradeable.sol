// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IEcoOwnable, EcoOwnable } from "./EcoOwnable.sol";
import { AccessControlEnumerableUpgradeable, AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import { IAccessControlEnumerable, IAccessControl } from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

interface IPausable {
    function pause() external;

    function unpause() external;
}

interface IMulticall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

interface ISelectorControl is IAccessControl {
    error SelectorRoleExist();
    error SelectorRoleNotExist();

    function hasSelectorRole(bytes4 role, address account) external view returns (bool);

    function getSelectorRoleAdmin(bytes4 role) external view returns (bytes32);

    function grantSelectorRole(bytes4 role, address account) external;

    function revokeSelectorRole(bytes4 role, address account) external;

    function renounceSelectorRole(bytes4 role, address callerConfirmation) external;
}

interface ISelectorControlEnumerable is IAccessControlEnumerable, ISelectorControl {
    function getSelectorRoleMember(bytes4 role, uint256 index) external view returns (address);

    function getSelectorRoleMemberCount(bytes4 role) external view returns (uint256);
}

interface ISelectorRoleControl is ISelectorControlEnumerable, IPausable {}

abstract contract SelectorRoleControlUpgradeable is
    Initializable,
    ISelectorRoleControl,
    EcoOwnable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    function initSelectorRoleControl(address initialOnwer) public initializer {
        _initEcoOwnable(initialOnwer);
        __Pausable_init();
        __AccessControlEnumerable_init();
    }

    modifier onlyAdmin() {
        _onlyAdmin(_msgSender());
        _;
    }

    // owner or selector role
    function _onlyAdmin(address account) internal view {
        if (owner() != account) _checkRole(msg.sig, account);
    }

    function grantSelectorRole(bytes4 selector, address account) public virtual override onlyAdmin {
        if (!_grantRole(selector, account)) revert SelectorRoleExist();
    }

    function revokeSelectorRole(bytes4 selector, address account) public virtual override onlyAdmin {
        if (!_revokeRole(selector, account)) revert SelectorRoleNotExist();
    }

    // IPausable
    function pause() public virtual override onlyAdmin {
        _pause();
    }

    function unpause() public virtual override onlyAdmin {
        _unpause();
    }

    function hasSelectorRole(bytes4 role, address account) external view override returns (bool) {
        return hasRole(role, account);
    }

    function getSelectorRoleAdmin(bytes4 role) external view override returns (bytes32) {
        return getRoleAdmin(role);
    }

    function renounceSelectorRole(bytes4 role, address callerConfirmation) external override {
        if (callerConfirmation != _msgSender()) revert AccessControlBadConfirmation();
        if (!_revokeRole(role, callerConfirmation)) revert SelectorRoleNotExist();
    }

    function getSelectorRoleMember(bytes4 role, uint256 index) external view override returns (address) {
        return getRoleMember(role, index);
    }

    function getSelectorRoleMemberCount(bytes4 role) external view override returns (uint256) {
        return getRoleMemberCount(role);
    }
}
