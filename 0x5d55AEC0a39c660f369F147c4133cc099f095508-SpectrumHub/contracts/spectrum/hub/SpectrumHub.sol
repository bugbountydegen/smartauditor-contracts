// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { SpectrumHubEntry } from "./SpectrumHubEntry.sol";

import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

contract SpectrumHub is SpectrumHubEntry, MulticallUpgradeable {
    constructor() {
        initSelectorRoleControl(_msgSender());
    }
}
