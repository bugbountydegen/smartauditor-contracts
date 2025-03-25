// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVaultFactory {
    function feeTo() external view returns (address);

    function WETH() external view returns (address);
}
