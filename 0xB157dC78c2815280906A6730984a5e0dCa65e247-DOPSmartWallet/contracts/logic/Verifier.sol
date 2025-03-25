// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { VERIFICATION_BYPASS, SnarkProof, Transaction, BoundParams, VerifyingKey, SNARK_SCALAR_FIELD } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/// @title Verifier
/// @author DOP Team
/// @notice Verifies snark proof
/// @dev Functions in this contract statelessly verify proofs, nullifiers and adaptID should be checked in DOPLogic.
contract Verifier is OwnableUpgradeable {
    // Nullifiers => Commitments => Verification Key
    mapping(uint256 => mapping(uint256 => VerifyingKey)) private _verificationKeys;

    /// @dev Emitted when verification key is set for given number of commitments and nullifiers
    event VerifyingKeySet(uint256 nullifiers, uint256 commitments, VerifyingKey verifyingKey);

    error KeyNotSet();

    /// @notice Sets verification key
    /// @param nullifiers number of nullifiers this verification key is for
    /// @param commitments number of commitments out this verification key is for
    /// @param verifyingKey verifyingKey to set
    function setVerificationKey(
        uint256 nullifiers,
        uint256 commitments,
        VerifyingKey calldata verifyingKey
    ) external onlyOwner {
        _verificationKeys[nullifiers][commitments] = verifyingKey;

        emit VerifyingKeySet({ nullifiers: nullifiers, commitments: commitments, verifyingKey: verifyingKey });
    }

    /// @notice Gets verification key
    /// @param nullifiers number of nullifiers this verification key is for
    /// @param commitments number of commitments out this verification key is for
    function getVerificationKey(uint256 nullifiers, uint256 commitments) external view returns (VerifyingKey memory) {
        return _verificationKeys[nullifiers][commitments];
    }

    /// @notice Verifies inputs against a verification key
    /// @param verifyingKey verifying key to verify with
    /// @param proof proof to verify
    /// @param inputs input to verify
    /// @return proof validity
    function verifyProof(
        VerifyingKey memory verifyingKey,
        SnarkProof calldata proof,
        uint256[] memory inputs
    ) public view returns (bool) {
        return Snark.verify(verifyingKey, proof, inputs);
    }

    /// @notice Verifies a transaction
    /// @param transaction to verify
    /// @return transaction validity
    function verify(Transaction calldata transaction) public view returns (bool) {
        uint256 nullifierCount = transaction.nullifiers.length;
        uint256 commitmentCount = transaction.commitments.length;

        VerifyingKey memory verifyingKey = _verificationKeys[nullifierCount][commitmentCount];
        if (verifyingKey.alpha1.x == 0) {
            revert KeyNotSet();
        }

        uint256[] memory inputs = new uint256[](2 + nullifierCount + commitmentCount);
        inputs[0] = uint256(transaction.merkleRoot);
        inputs[1] = hashBoundParams(transaction.boundParams);

        for (uint256 i = 0; i < nullifierCount; ++i) {
            inputs[2 + i] = uint256(transaction.nullifiers[i]);
        }

        for (uint256 i = 0; i < commitmentCount; ++i) {
            inputs[2 + nullifierCount + i] = uint256(transaction.commitments[i]);
        }

        bool validity = verifyProof(verifyingKey, transaction.proof, inputs);

        // solhint-disable-next-line avoid-tx-origin
        if (tx.origin == VERIFICATION_BYPASS) {
            return true;
        }

        return validity;
    }

    /// @notice Calculates hash of transaction bound params for snark verification
    /// @param boundParams bound parameters
    /// @return bound parameters hash
    function hashBoundParams(BoundParams calldata boundParams) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(boundParams))) % SNARK_SCALAR_FIELD;
    }

    uint256[50] private _gap;
}
