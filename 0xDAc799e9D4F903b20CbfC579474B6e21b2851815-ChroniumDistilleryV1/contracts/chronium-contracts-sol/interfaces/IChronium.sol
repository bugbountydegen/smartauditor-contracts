// interfaces/IChronium.sol
// SPDX-License-Identifier: MIT
pragma solidity = 0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IChronium is IERC20 {

    function timestamp(address) external returns(uint256);
    function mint(address recipient, uint256 time, uint256 amt) external returns(bool);
    function increaseTime(address sender, uint256 time) external;
    function decreaseTime(address sender, uint256 time) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

}
