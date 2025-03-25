// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract VaultFactory is UpgradeableBeacon, IVaultFactory {
    using Address for address;

    address public WETH;
    address public feeTo;
    bytes21 private immutable _create2Prefix;

    event Deployed(address _proxy, address _sender, bytes32 _salt);

    constructor(address _owner, address _implementation) UpgradeableBeacon(_implementation) {
        _create2Prefix = bytes21(uint168((0xff << 160) | uint256(uint160(address(this)))));
        _transferOwnership(_owner);
    }

    /**
     * @dev Setup WETH address for wrapping/unwrapping
     * @dev requires feeTo to call. Done this way to preserve create2 addresses
     * @param _WETH WETH or wrapped native gas token address
     */
    function setupWETH(address _WETH) public onlyOwner {
        require(WETH == address(0), "WETH already setup");
        WETH = _WETH;
    }

    /**
     * @notice hand over feeTo privilege
     * @dev only callable by current feeTo or set by owner
     * @param newFeeTo address of new fee owner
     */
    function handoverFeeTo(address newFeeTo) public {
        require(_msgSender() == feeTo || (_msgSender() == owner() && feeTo == address(0)), "VaultFactory: need Feeto");
        feeTo = newFeeTo;
    }

    /**
     * @dev Deploy a new beacon proxy. The salt is combined with the message sender to
     * ensure that two different users cannot deploy proxies to the same
     * address. The address deployed to does not depend on the current
     * implementation or on the initializer.
     * @param initializer The encdoded function data and parameters of the intializer
     * @param salt The salt used for deployment
     */
    function deploy(bytes calldata initializer, bytes32 salt)
        public
        payable
        virtual
        returns (address proxy, bytes memory returnData)
    {
        address msgSender = _msgSender();
        // constructor takes in address + bytes array
        bytes memory bytecode = bytes.concat(type(BeaconProxy).creationCode, bytes32(uint256(uint160(address(this)))), bytes32(uint(64)), bytes32(0));
        bytes32 proxySalt = keccak256(abi.encodePacked(msgSender, salt));
        {
            assembly ("memory-safe") {
                proxy := create2(0, add(bytecode, 0x20), mload(bytecode), proxySalt)
                if iszero(extcodesize(proxy)) {
                    revert(0, 0)
                }
            }
        }

        // Rolling the initialization into the construction of the proxy is either
        // very expensive (if the initializer has to be saved to storage and then
        // retrived by the initializer by a callback) (>200 gas per word as of
        // EIP-2929/Berlin) or creates dependence of the deployed address on the
        // contents of the initializer (if it's supplied as part of the
        // initcode). Therefore, we elect to send the initializer as part of a call
        // to the proxy AFTER deployment.
        returnData = proxy.functionCallWithValue(initializer, msg.value, "BeaconCache: initialize failed");

        emit Deployed(proxy, msgSender, salt);
    }
}
