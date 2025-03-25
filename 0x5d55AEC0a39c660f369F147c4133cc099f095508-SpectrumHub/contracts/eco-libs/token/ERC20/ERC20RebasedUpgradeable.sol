// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC20, IERC20Metadata, IERC20Rebased, IERC20Stake } from "./IERC20.sol";

import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { ERC20MetadataUpgradeable } from "./ERC20MetadataUpgradeable.sol";

abstract contract ERC20RebasedUpgradeable is
    IERC20Rebased,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20MetadataUpgradeable
{
    // keccak256(abi.encode(uint256(keccak256("eco.storage.ERC20RebasedUpgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20RebasedUpgradeableStorageLocation =
        0x1ea3549028b4c9293c86cc095a7087c2444497b8b58d770ab753d35bd0399d00;

    struct ERC20RebasedUpgradeableStorage {
        address underlying;
        mapping(address account => uint256) _shares;
        uint256 _totalShares;
    }

    function _getERC20RebasedUpgradeableStorage() internal pure returns (ERC20RebasedUpgradeableStorage storage $) {
        assembly {
            $.slot := ERC20RebasedUpgradeableStorageLocation
        }
    }

    function initEcoERC20Rebase(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        _initEcoERC20Metadata(_name, _symbol, _decimals);
        _initERC20Rebased(_underlying);
        __ERC20Permit_init(name());
    }

    function _initERC20Rebased(address _underlying) internal onlyInitializing {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        _checkRebaseUnderlying(_underlying);
        $.underlying = _underlying;
    }

    function _checkRebaseUnderlying(address _underlying) internal virtual;

    function _totalSupply() internal view virtual returns (uint256);

    function underlying() public view virtual returns (address) {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        return $.underlying;
    }

    function totalSupply() public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _totalSupply();
    }

    function balanceOf(address account) public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
        return calcBalance(shareOf(account));
    }

    function totalShares() public view virtual override returns (uint256 _totalShares) {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        return $._totalShares;
    }

    function shareOf(address account) public view override returns (uint256) {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        return $._shares[account];
    }

    function stake(uint256 value, address receiver) public payable override {
        _receiveUnderlying(value, _msgSender());
        _mint(receiver, value);
    }

    function _receiveUnderlying(uint256 value, address caller) internal virtual;

    function unstake(uint256 value, address receiver) public override {
        _burn(_msgSender(), value);
        _sendUnderlying(receiver, value);
    }

    function _sendUnderlying(address receiver, uint256 value) internal virtual;

    function _totalSharesOrDefault() internal view returns (uint256) {
        uint256 _totalShares = totalShares();
        if (_totalShares == 0) _totalShares = totalSupply();
        return _totalShares;
    }

    function calcBalance(uint256 share) public view override returns (uint256 balance) {
        balance = _totalSharesOrDefault();
        if (balance == 0) return 0;
        else return (totalSupply() * share) / balance;
    }

    function calcShare(uint256 balance) public view override returns (uint256) {
        return _calcBurnShare(balance);
    }

    function _effectiveSupply(uint256 balance) internal view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == balance) return totalSupply_;
        // "totalSupply_ < balance" is not expected, but adding underflow protection is advisable for robustness.
        return totalSupply_ - balance;
    }

    function _calcMintShare(uint256 balance) public view returns (uint256) {
        return (_totalSharesOrDefault() * balance) / _effectiveSupply(balance);
    }

    function _calcBurnShare(uint256 balance) public view returns (uint256 share) {
        share = totalSupply();
        if (share == 0) return 0;
        else return (_totalSharesOrDefault() * balance) / share;
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        ERC20RebasedUpgradeableStorage storage $ = _getERC20RebasedUpgradeableStorage();
        uint256 share = from == address(0) ? _calcMintShare(value) : _calcBurnShare(value);
        if (from == address(0)) {
            unchecked {
                $._totalShares += share;
            }
        } else {
            uint256 fromBalance = balanceOf(from);
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                $._shares[from] -= share;
            }
        }

        if (to == address(0)) {
            unchecked {
                $._totalShares -= share;
            }
        } else {
            unchecked {
                $._shares[to] += share;
            }
        }

        emit Transfer(from, to, value);
    }

    function name()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.name();
    }

    function symbol()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (string memory)
    {
        return super.symbol();
    }

    function decimals()
        public
        view
        override(ERC20MetadataUpgradeable, ERC20Upgradeable, IERC20Metadata)
        returns (uint8)
    {
        return super.decimals();
    }
}
