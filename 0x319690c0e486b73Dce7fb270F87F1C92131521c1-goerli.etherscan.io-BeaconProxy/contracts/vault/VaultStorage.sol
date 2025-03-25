// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract VaultStorageV1 {
    IVaultFactory public vaultFactory;
    IWETH WETH;
}
