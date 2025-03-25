// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGelato1Balance} from "./interfaces/IGelato1Balance.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {NATIVE_TOKEN, FEE_COLLECTOR} from "./constants/Addresses.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IDai} from "./interfaces/IDai.sol";
import {
    MerkleProof
} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Fee} from "./structs/Fee.sol";
import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/// @dev Contract will have open infinite approvals
/// therefore, an open transferFrom must NOT live on this contract
// solhint-disable-next-line max-states-count
contract Gelato1Balance is IGelato1Balance, Proxied, ERC2771Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes32 public root;

    mapping(address => mapping(address => uint256)) public totalDepositedAmount;
    mapping(address => mapping(address => uint256)) public totalWithdrawnAmount;
    uint256 public managerNonce;

    EnumerableSet.AddressSet private _managers;
    EnumerableSet.AddressSet private _whitelistedTokens;

    modifier onlyManager() {
        require(_managers.contains(_msgSender()), "Gelato1Balance.onlyManager");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {}

    function depositNative(address _sponsor) external payable override {
        require(msg.value > 0, "Gelato1Balance.depositNative: zero deposit");
        require(
            _sponsor != address(0),
            "Gelato1Balance.depositNative: invalid sponsor"
        );

        totalDepositedAmount[_sponsor][NATIVE_TOKEN] += msg.value;

        emit LogDeposit(root, _sponsor, NATIVE_TOKEN, msg.value);
    }

    function depositToken(
        address _sponsor,
        IERC20 _token,
        uint256 _amount
    ) external override {
        _depositToken(_sponsor, _token, _amount);
    }

    /// @notice If infinite approving, use this fn for first time entering
    /// afterwards, use depositToken directly to make use of open approval
    function depositTokenWithPermit(
        address _sponsor,
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        // OpenZeppelin EIP-2612 Permit implementation
        IERC20Permit(_token).permit(
            _msgSender(),
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        _depositToken(_sponsor, IERC20(_token), _amount);
    }

    /// @notice Use this fn for first time entering, afterwards
    /// use depositToken directly to make use of open approval
    /// @dev DAI permit only works with infinite approve
    // solhint-disable-next-line max-line-length
    // https://github.com/makerdao/dss/blob/fa4f6630afb0624d04a003e920b0d71a00331d98/src/dai.sol#L124
    function depositDaiWithPermit(
        address _sponsor,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        // Infinite approve
        IDai(_token).permit(
            _msgSender(),
            address(this),
            _nonce,
            _expiry,
            true,
            _v,
            _r,
            _s
        );

        _depositToken(_sponsor, IERC20(_token), _amount);
    }

    function requestWithdrawal(
        address _token,
        uint256 _withdrawalAmount
    ) external override {
        require(
            _withdrawalAmount > 0,
            "Gelato1Balance.requestWithdrawal: zero amount"
        );

        address msgSender = _msgSender();

        uint256 totalDeposited = totalDepositedAmount[msgSender][_token];
        uint256 totalWithdrawn = totalWithdrawnAmount[msgSender][_token];

        require(
            _withdrawalAmount <= totalDeposited - totalWithdrawn,
            "Gelato1Balance.requestWithdrawal: excess"
        );

        emit LogRequestWithdrawal(root, msgSender, _token, _withdrawalAmount);
    }

    // solhint-disable-next-line function-max-lines
    function cancelWithdrawalRequest(
        address _token,
        uint256 _cancelledAmount,
        uint256 _totalValidRequestedWithdrawAmount,
        bytes32[] calldata _merkleProof
    ) external override {
        require(
            _cancelledAmount > 0,
            "Gelato1Balance.cancelWithdrawalRequest: zero amount"
        );

        address msgSender = _msgSender();

        bytes32 leafHash = keccak256(
            abi.encode(
                block.chainid,
                msgSender,
                _token,
                _totalValidRequestedWithdrawAmount
            )
        );

        bytes32 rootCache = root;
        _validateMerkleProof(leafHash, _merkleProof, rootCache);

        uint256 newTotalWithdrawn = totalWithdrawnAmount[msgSender][_token] +
            _cancelledAmount;
        uint256 oldTotalDeposited = totalDepositedAmount[msgSender][_token];

        require(
            newTotalWithdrawn <= oldTotalDeposited,
            "Gelato1Balance.cancelWithdrawalRequest: excess"
        );

        require(
            newTotalWithdrawn <= _totalValidRequestedWithdrawAmount,
            "Gelato1Balance.cancelWithdrawalRequest: _totalValidRequestedWithdrawAmount"
        );

        totalWithdrawnAmount[msgSender][_token] = newTotalWithdrawn;

        totalDepositedAmount[msgSender][_token] =
            oldTotalDeposited +
            _cancelledAmount;

        emit LogCancelWithdrawalRequest(
            rootCache,
            msgSender,
            _token,
            _cancelledAmount
        );
    }

    function withdraw(
        address _token,
        uint256 _amount,
        uint256 _totalValidRequestedWithdrawAmount,
        bytes32[] calldata _merkleProof
    ) external override {
        require(_amount > 0, "Gelato1Balance.withdraw: zero amount");

        address msgSender = _msgSender();

        bytes32 leafHash = keccak256(
            abi.encode(
                block.chainid,
                msgSender,
                _token,
                _totalValidRequestedWithdrawAmount
            )
        );

        bytes32 rootCache = root;
        _validateMerkleProof(leafHash, _merkleProof, rootCache);

        uint256 newTotalWithdrawn = totalWithdrawnAmount[msgSender][_token] +
            _amount;

        require(
            newTotalWithdrawn <= totalDepositedAmount[msgSender][_token],
            "Gelato1Balance.withdraw: excess"
        );
        require(
            newTotalWithdrawn <= _totalValidRequestedWithdrawAmount,
            "Gelato1Balance.withdraw: _totalValidRequestedWithdrawAmount"
        );

        totalWithdrawnAmount[msgSender][_token] = newTotalWithdrawn;

        _transferTo(_token, msgSender, _amount);

        emit LogSponsorWithdrawal(rootCache, msgSender, _token, _amount);
    }

    function addManager(address _manager) external override onlyProxyAdmin {
        require(
            _manager != address(0),
            "Gelato1Balance.addManager: zero address"
        );

        _managers.add(_manager);

        emit LogAddManager(_manager);
    }

    function removeManager(address _manager) external override onlyProxyAdmin {
        require(
            _manager != address(0),
            "Gelato1Balance.removeManager: zero address"
        );

        _managers.remove(_manager);

        emit LogRemoveManager(_manager);
    }

    function addToken(address _token) external override onlyProxyAdmin {
        require(_token != address(0), "Gelato1Balance.addToken: zero address");
        _whitelistedTokens.add(_token);

        emit LogAddToken(_token);
    }

    function removeToken(address _token) external override onlyProxyAdmin {
        require(
            _whitelistedTokens.contains(_token),
            "Gelato1Balance.removeToken: whitelist"
        );

        _whitelistedTokens.remove(_token);

        emit LogRemoveToken(_token);
    }

    function settle(
        bytes32 _root,
        bytes32 _newRoot
    ) external override onlyManager {
        require(root == _root, "Gelato1Balance.settle: root mismatch");
        root = _newRoot;

        emit LogSettlement(_newRoot, _msgSender());
    }

    function settleWithSignature(
        bytes32 _newRoot,
        bytes calldata _managerSignature
    ) external override {
        bytes32 digest = keccak256(
            abi.encode(block.chainid, root, _newRoot, managerNonce)
        );
        managerNonce++;

        address manager = _verifyManagerSignature(digest, _managerSignature);

        root = _newRoot;

        emit LogSettlement(_newRoot, manager);
    }

    function collectFees(Fee[] calldata _fees) external override onlyManager {
        _collectFees(_fees);
    }

    function collectFeesWithSignature(
        Fee[] calldata _fees,
        bytes calldata _managerSignature
    ) external override {
        bytes32 digest = keccak256(
            abi.encode(block.chainid, _fees, managerNonce)
        );
        managerNonce++;

        _verifyManagerSignature(digest, _managerSignature);

        _collectFees(_fees);
    }

    /// VIEW FUNCTIONS
    function managers()
        external
        view
        override
        returns (address[] memory managers_)
    {
        managers_ = _managers.values();
    }

    function tokens()
        external
        view
        override
        returns (address[] memory whitelistedTokens_)
    {
        whitelistedTokens_ = _whitelistedTokens.values();
    }

    function _collectFees(Fee[] calldata _fees) private {
        bytes32 rootCache = root;

        for (uint256 i; i < _fees.length; i++) {
            require(
                _fees[i].amount > 0,
                "Gelato1Balance._collectFees: zero amount"
            );
            // Gelato's fee accounting is represented by address(0)
            bytes32 leafHash = keccak256(
                abi.encode(
                    block.chainid,
                    address(0),
                    _fees[i].token,
                    _fees[i].totalValidRequestedWithdrawAmount
                )
            );

            _validateMerkleProof(leafHash, _fees[i].merkleProof, rootCache);

            uint256 newTotalWithdrawn = totalWithdrawnAmount[address(0)][
                _fees[i].token
            ] += _fees[i].amount;

            require(
                newTotalWithdrawn <= _fees[i].totalValidRequestedWithdrawAmount,
                "Gelato1Balance._collectFees: _totalValidRequestedWithdrawAmount"
            );

            _transferTo(_fees[i].token, FEE_COLLECTOR, _fees[i].amount);

            emit LogCollectFee(
                rootCache,
                FEE_COLLECTOR,
                _fees[i].token,
                _fees[i].amount
            );
        }
    }

    /// PRIVATE FUNCTIONS
    function _depositToken(
        address _sponsor,
        IERC20 _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "Gelato1Balance._depositToken: zero amount");
        require(
            _sponsor != address(0),
            "Gelato1Balance._depositToken: zero address"
        );
        require(
            _whitelistedTokens.contains(address(_token)),
            "Gelato1Balance._depositToken: whitelist"
        );

        totalDepositedAmount[_sponsor][address(_token)] += _amount;
        // Assumes we have not whitelisted fee-on-transfer tokens
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        emit LogDeposit(root, _sponsor, address(_token), _amount);
    }

    function _transferTo(address _token, address _to, uint256 _amount) private {
        if (_token == NATIVE_TOKEN) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "Gelato1Balance._transferTo: failed");
        } else {
            IERC20 token = IERC20(_token);
            token.safeTransfer(_to, _amount);
        }
    }

    function _verifyManagerSignature(
        bytes32 _digest,
        bytes calldata _managerSignature
    ) private view returns (address) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            _digest,
            _managerSignature
        );
        require(
            error == ECDSA.RecoverError.NoError &&
                _managers.contains(recovered),
            "Gelato1Balance._verifyManagerSignature: invalid"
        );

        return recovered;
    }

    function _validateMerkleProof(
        bytes32 _leafHash,
        bytes32[] calldata _merkleProof,
        bytes32 _root
    ) private pure {
        require(
            MerkleProof.verify(_merkleProof, _root, _leafHash),
            "Gelato1Balance._validateMerkleProof: invalid"
        );
    }
}
