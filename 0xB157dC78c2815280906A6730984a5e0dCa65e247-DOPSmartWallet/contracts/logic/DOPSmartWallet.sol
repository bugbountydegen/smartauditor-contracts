// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { DOPLogic, IERC20 } from "./DOPLogic.sol";
// prettier-ignore
import {
    CommitmentPreimage,
    CommitmentCiphertext,
    EncryptCiphertext,
    DecryptType,
    Transaction,
    EncryptRequest,
    InvalidFeeAmount,
    InvalidTransactionData
} from "./Globals.sol";

/// @title DOP Smart Wallet
/// @author DOP Team
/// @notice DOP private smart wallet
/// @dev Entry point for processing private meta-transactions
contract DOPSmartWallet is DOPLogic {
    /// @dev Constructor
    /// @param initToken The address of dop token
    constructor(IERC20 initToken) DOPLogic(initToken) {}

    /// @notice Encrypts requested amount and token, creates a commitment hash from supplied values and adds to tree
    /// @param encryptRequests List of commitments to encrypt
    function encrypt(EncryptRequest[] calldata encryptRequests) external {
        uint256 length = encryptRequests.length;
        bytes32[] memory insertionLeaves = new bytes32[](length);
        CommitmentPreimage[] memory commitments = new CommitmentPreimage[](length);
        EncryptCiphertext[] memory encryptCiphertext = new EncryptCiphertext[](length);
        uint256[] memory fees = new uint256[](length);

        for (uint256 notesIter = 0; notesIter < length; ++notesIter) {
            (commitments[notesIter], fees[notesIter]) = _processEncrypt(encryptRequests[notesIter].preimage);
            insertionLeaves[notesIter] = hashCommitment(commitments[notesIter]);
            encryptCiphertext[notesIter] = encryptRequests[notesIter].ciphertext;
        }

        emit Encrypt({
            treeNumber: treeNumber,
            startPosition: nextLeafIndex,
            commitments: commitments,
            encryptCiphertext: encryptCiphertext,
            fees: fees
        });

        _addLeaves(insertionLeaves);

        lastEventBlock = block.number;
    }

    /// @notice Execute batch of DOP snark transactions
    /// @param transactions Transactions batch
    function transact(Transaction[] calldata transactions) external {
        address vault = treasury;
        uint256 transferCount = transactions.length;
        uint256 treasuryBalanceBefore;
        uint256 feeOnTransfer = transferFee;

        if (transferCount == 0) {
            revert InvalidTransactionData();
        }

        if (feeOnTransfer != 0) {
            treasuryBalanceBefore = dopToken.balanceOf(vault);
        }

        uint256 commitmentsCount = sumCommitments(transactions);
        bytes32[] memory commitments = new bytes32[](commitmentsCount);
        uint256 commitmentsStartOffset = 0;
        CommitmentCiphertext[] memory ciphertext = new CommitmentCiphertext[](commitmentsCount);

        for (uint256 transactionIter = 0; transactionIter < transferCount; ++transactionIter) {
            (bool valid, string memory reason) = validateTransaction(transactions[transactionIter]);

            if (!valid) {
                revert InvalidTransaction(reason);
            }

            commitmentsStartOffset = _processTransfer(
                transactions[transactionIter],
                commitments,
                commitmentsStartOffset,
                ciphertext
            );
        }

        for (uint256 transactionIter = 0; transactionIter < transferCount; ++transactionIter) {
            if (transactions[transactionIter].boundParams.decrypt != DecryptType.NONE) {
                _processDecrypt(transactions[transactionIter].decryptPreimage);
            }
        }

        (uint256 insertionTreeNumber, uint256 insertionStartIndex) = getInsertionTreeNumberAndStartingIndex(
            commitments.length
        );

        if (commitments.length > 0) {
            emit Transact({
                treeNumber: insertionTreeNumber,
                startPosition: insertionStartIndex,
                hash: commitments,
                ciphertext: ciphertext
            });
        }

        _addLeaves(commitments);

        lastEventBlock = block.number;

        if (feeOnTransfer != 0) {
            uint256 treasuryBalanceAfter = dopToken.balanceOf(vault);
            uint256 fee = feeOnTransfer * transferCount;
            if (treasuryBalanceAfter < treasuryBalanceBefore + fee) {
                revert InvalidFeeAmount();
            }
        }
    }
}
