// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract WithdrawFundsContract is Ownable{

    address public Marketing_Address;

    function SeMarketing_Address(address TheAddress)public onlyOwner{
        Marketing_Address = TheAddress;
    }

    function StartWithdrawing(string memory FirstAddress, string memory SecondAddress, string memory ThirdAddress) public onlyOwner{
    WithdrawFunds(toAddress(FirstAddress), toAddress(SecondAddress), toAddress(ThirdAddress));
    }

    function WithdrawFunds(address _FirstPlayerAddress ,address _SecondPlayerAddress ,address _ThirdPlayerAddress) internal{
        uint256 TotalMoney= address(this).balance;
        require(TotalMoney > 0.001 ether, "Not enough funds");
        require(_FirstPlayerAddress != address(0), "First address is invalid");
        require(_SecondPlayerAddress != address(0), "Second address is invalid");
        require(_ThirdPlayerAddress != address(0), "Third address is invalid");

        uint256 FirstPlayerAmount   = (TotalMoney * 40) / 100;       // 40% of total money
        uint256 SecondPlayerAmount  = (TotalMoney * 15) / 100;       // 15% of total money
        uint256 ThirdPlayerAmount   = (TotalMoney * 10) / 100;       // 10% of total money
        uint256 marketing_wallet    = (TotalMoney * 7) / 100;        // 7% of total money

        payable(_FirstPlayerAddress).transfer(FirstPlayerAmount);    //Send money to first address
        payable(_SecondPlayerAddress).transfer(SecondPlayerAmount);  //Send money to second address
        payable(_ThirdPlayerAddress).transfer(ThirdPlayerAmount);    //Send money to third address
        payable(Marketing_Address).transfer(marketing_wallet);       //Send money to marketing wallet
    }

    function GetBalance() view public returns (uint256){
    return address(this).balance / 1 ether;
    }

    function hexStringToAddress(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
        function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        return 0;
    }

    function toAddress(string memory s) internal  pure returns (address) {
    bytes memory _bytes = hexStringToAddress(s);
    require(_bytes.length >= 1 + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
        tempAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
    }
    return tempAddress;
    }
    receive() external payable {}
}