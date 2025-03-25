// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockERC677} from "./MockERC677.sol";
import {IERC1363} from "../interfaces/IERC20/IERC1363.sol";
import {IERC1363Spender} from "../interfaces/IERC20/IERC1363Spender.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract MockERC1363 is MockERC677 {
    using Address for address;

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) public virtual returns (bool) {
        approve(spender, amount);
        require(_checkOnApprovalReceived(spender, amount, data), "ERC1363: _checkOnApprovalReceived reverts");
        return true;
    }

    function _checkOnApprovalReceived(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data);
        return retval == IERC1363Spender.onApprovalReceived.selector;
    }
}
