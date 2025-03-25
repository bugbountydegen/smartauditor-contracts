// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

abstract contract Locker {
    bytes32 constant SLOT = 0;

    modifier lockTheSwap() {
        assembly {
            if tload(SLOT) { revert(0, 0) }
            tstore(SLOT, 1)
        }
        _;
        assembly {
            tstore(SLOT, 0)
        }
    }

    function inSwapAndLiquify() public view returns (bool v) {
        assembly {
            v := tload(SLOT)
        }
    }
}
