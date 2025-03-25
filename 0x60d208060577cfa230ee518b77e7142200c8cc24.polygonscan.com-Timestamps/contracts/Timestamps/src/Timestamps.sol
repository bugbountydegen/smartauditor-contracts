//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC404/ERC404.sol";
import "./ITimestampGenerator.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Timestamps is ERC404 {
    ITimestampGenerator public generator;

    constructor(address _owner,ITimestampGenerator newGenerator) ERC404("Timestamps", "TIMESTAMPS", 18, 10000, _owner) {
        generator = newGenerator;
        balanceOf[_owner] = 10000 * 10 ** 18;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 timestamp = timestamps[id];
        return generator.tokenURI(id, timestamp);
    }
}
