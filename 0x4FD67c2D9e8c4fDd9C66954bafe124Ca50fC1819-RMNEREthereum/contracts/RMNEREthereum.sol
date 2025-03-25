// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";

contract RMNEREthereum is OFT {
    address private _admin;
    error AddressInvalid(address account);
    error AdminUnauthorizedAccount(address account);

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address admin__
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        if (admin__ == address(0)) {
            revert AddressInvalid(address(0));
        }
        _admin = admin__;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _checkAdmin() internal view virtual {
        if (admin() != _msgSender()) {
            revert AdminUnauthorizedAccount(_msgSender());
        }
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address old = _admin;
        _admin = newAdmin;
        emit AdminTransferred(old, newAdmin);
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyAdmin {
        _burn(msg.sender, amount);
    }
}
