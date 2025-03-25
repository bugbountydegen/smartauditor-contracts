// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { Commitments } from "./Commitments.sol";
// prettier-ignore
import {
    CommitmentCiphertext,
    CommitmentPreimage,
    IdenticalValue,
    InvalidAddress,
    EncryptCiphertext,
    SNARK_SCALAR_FIELD,
    TokenData,
    TokenType,
    Transaction,
    UnsafeVectors,
    DecryptType,
    UnsupportedToken
} from "./Globals.sol";
import { PoseidonT4 } from "./PoseidonT4.sol";
import { Protection } from "./Protection.sol";
import { TokenBlocklist } from "./TokenBlocklist.sol";
import { Verifier } from "./Verifier.sol";

/// @title DOP Logic
/// @author DOP Team
/// @notice Logic to process transactions
contract DOPLogic is Initializable, OwnableUpgradeable, Commitments, TokenBlocklist, Verifier {
    using SafeERC20 for IERC20;

    // Number of basis points that equal 100%
    uint120 private constant BASIS_POINTS = 10000;
    uint120 private constant MAX_ENCRYPT_FEE_BPS = 5000;
    uint120 private constant MAX_DECRYPT_FEE_BPS = 5000;

    // Max limit for transfer fee, in units of DOP
    uint120 private constant MAX_TRANSFEE_FEE = 100_000 * 10 ** 18;

    // Fee in basis points (bps)
    uint120 public encryptFeeBps;
    uint120 public decryptFeeBps;

    // Send/Transfer fee in units of DOP
    uint120 public transferFee;

    // Treasury contract
    address payable public treasury;

    // DOP token contract
    IERC20 public immutable dopToken;

    // Chainalysis Protection list
    Protection public protection;

    // Last event block - to assist with scanning
    uint256 public lastEventBlock;

    // Whether decrypting is enabled or disabled
    bool public decryptEnabled;

    // Safety vectors
    mapping(uint256 => bool) public snarkSafetyVector;

    // Token ID mapping
    mapping(bytes32 => TokenData) public tokenIDMapping;

    /// @dev Emitted when treasury is changed
    event TreasuryChange(address treasury);

    /// @dev Emitted when protection list is changed
    event ProtectionChange(Protection indexed protection);

    /// @dev Emitted when fee is changed
    event FeeChange(uint256 encryptFeeBps, uint256 transferFee, uint256 decryptFeeBps);

    /// @dev Emitted when tokens are transferred
    event Transact(uint256 treeNumber, uint256 startPosition, bytes32[] hash, CommitmentCiphertext[] ciphertext);

    /// @dev Emitted when adding a snark safety vector
    event VectorAdded(uint256 vector, bool state);

    /// @dev Emitted when removing a snark safety vector
    event VectorRemoved(uint256 vector, bool state);

    /// @dev Emitted when tokens are encrypted
    event Encrypt(
        uint256 treeNumber,
        uint256 startPosition,
        CommitmentPreimage[] commitments,
        EncryptCiphertext[] encryptCiphertext,
        uint256[] fees
    );

    /// @dev Emitted when tokens are decrypted
    event Decrypt(address to, TokenData token, uint256 amount, uint256 fee);

    /// @dev Emitted when any commitment is nullified
    event Nullified(uint16 treeNumber, bytes32[] nullifier);

    /// @dev Emitted when decrypt is enabled
    event DecryptEnabled();

    error InvalidCommitment(string reason);
    error InvalidDecrypt(string reason);
    error InvalidTransaction(string reason);
    error InvalidEncryptFee();
    error InvalidTransferFee();
    error InvalidDecryptFee();
    error ERC20TokenTransferFailed();
    error ERC721TokenTransferFailed();
    error NoteAlreadySpent();
    error DecryptDisabled();
    error DecryptAlreadyEnabled();

    /// @dev Constructor
    /// @param initToken The address of dop token
    constructor(IERC20 initToken) {
        if (address(initToken) == address(0)) {
            revert InvalidAddress();
        }

        dopToken = initToken;
    }

    /// @notice Change Protection list address, only callable by owner (governance contract)
    /// @param newProtection - Address of the new Protection list
    function changeProtection(Protection newProtection) external onlyOwner {
        _changeProtection(newProtection);
    }

    /// @notice Starts Decrypting
    function startDecrypt() external onlyOwner {
        if (decryptEnabled) {
            revert DecryptAlreadyEnabled();
        }

        decryptEnabled = true;

        emit DecryptEnabled();
    }

    /// @notice Safety check for badly behaving code
    function checkSafetyVectors() external {
        StorageSlot.getBooleanSlot(0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450).value = true;
        bool result = false;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0, caller())
            mstore(32, snarkSafetyVector.slot)
            let hash := keccak256(0, 64)
            result := sload(hash)
        }

        if (!result) {
            revert UnsafeVectors();
        }
    }

    /// @notice Adds or Removes safety vector
    /// @param vector - Note to change state
    /// @param state - New state of note
    function updateVector(uint256 vector, bool state) external onlyOwner {
        if (state) {
            emit VectorAdded(vector, state);
        } else {
            emit VectorRemoved(vector, state);
        }

        snarkSafetyVector[vector] = state;
    }

    /// @notice Initialize DOP contract
    /// @dev OpenZeppelin initializer ensures this can only be called once. This function also calls initializers on inherited contracts
    /// @param initTreasury - Address to send usage fees to
    /// @param initProtection - Chainalysis Protection list
    /// @param initEncryptFee - Encrypt fee
    /// @param initDecryptFee - Decrypt fee
    /// @param owner - Governance contract
    function initializeDOPLogic(
        address payable initTreasury,
        Protection initProtection,
        uint120 initEncryptFee,
        uint120 initTransferFee,
        uint120 initDecryptFee,
        address owner
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        Commitments._initializeCommitments();

        changeTreasury(initTreasury);
        _changeProtection(initProtection);
        changeFee(initEncryptFee, initTransferFee, initDecryptFee);

        OwnableUpgradeable.transferOwnership(owner);

        snarkSafetyVector[11991246288605609459798790887503763024866871101] = true;
        snarkSafetyVector[135932600361240492381964832893378343190771392134] = true;
        snarkSafetyVector[1165567609304106638376634163822860648671860889162] = true;
    }

    /// @notice Change treasury address, only callable by owner (governance contract)
    /// @dev This will change the address of the contract we're sending the fees to in the future. It won't transfer tokens
    /// already in the treasury
    /// @param newTreasury - Address of new treasury contract
    function changeTreasury(address payable newTreasury) public onlyOwner {
        if (newTreasury == address(0)) {
            revert InvalidAddress();
        }

        if (treasury == newTreasury) {
            revert IdenticalValue();
        }

        treasury = newTreasury;

        emit TreasuryChange({ treasury: newTreasury });
    }

    /// @notice Change fee rate for future transactions
    /// @param newEncryptFeeBps - Encrypt fee
    /// @param newTransferFee - Transfer fee,
    /// @param newDecryptFeeBps - Decrypt fee
    function changeFee(uint120 newEncryptFeeBps, uint120 newTransferFee, uint120 newDecryptFeeBps) public onlyOwner {
        if (encryptFeeBps != newEncryptFeeBps || transferFee != newTransferFee || decryptFeeBps != newDecryptFeeBps) {
            if (newEncryptFeeBps > MAX_ENCRYPT_FEE_BPS) {
                revert InvalidEncryptFee();
            }

            if (newDecryptFeeBps > MAX_DECRYPT_FEE_BPS) {
                revert InvalidDecryptFee();
            }

            if (newTransferFee > MAX_TRANSFEE_FEE) {
                revert InvalidTransferFee();
            }

            encryptFeeBps = newEncryptFeeBps;
            transferFee = newTransferFee;
            decryptFeeBps = newDecryptFeeBps;

            emit FeeChange({
                encryptFeeBps: newEncryptFeeBps,
                transferFee: newTransferFee,
                decryptFeeBps: newDecryptFeeBps
            });
        }
    }

    /// @notice Checks commitment ranges for validity
    /// @param note - Note to validate
    /// @return valid, reason
    function validateCommitmentPreimage(CommitmentPreimage calldata note) public view returns (bool, string memory) {
        if (note.value == 0) {
            return (false, "Invalid Note Value");
        }

        if (TokenBlocklist.tokenBlocklist[IERC20(note.token.tokenAddress)]) {
            return (false, "Unsupported Token");
        }

        if (uint256(note.npk) >= SNARK_SCALAR_FIELD) {
            return (false, "Invalid Note NPK");
        }

        if (note.token.tokenType == TokenType.ERC721 && note.value != 1) {
            return (false, "Invalid NFT Note Value");
        }

        if (protection.isSanctioned(msg.sender)) {
            return (false, "Call from Sanctioned Address");
        }

        return (true, "");
    }

    /// @notice Verifies transaction validity
    /// @param transaction - Transaction batch
    /// @return valid, reason
    function validateTransaction(Transaction calldata transaction) public view returns (bool, string memory) {
        if (tx.gasprice < transaction.boundParams.minGasPrice) {
            return (false, "Gas price too low");
        }

        if (
            transaction.boundParams.adaptContract != address(0) && transaction.boundParams.adaptContract != msg.sender
        ) {
            return (false, "Invalid Adapt Contract as Sender");
        }

        if (transaction.boundParams.chainID != block.chainid) {
            return (false, "ChainID mismatch");
        }

        if (!Commitments.rootHistory[transaction.boundParams.treeNumber][transaction.merkleRoot]) {
            return (false, "Invalid Merkle Root");
        }

        if (transaction.boundParams.decrypt != DecryptType.NONE) {
            if (!decryptEnabled) {
                revert DecryptDisabled();
            }
            // Ensure ciphertext length matches the commitments length (minus 1 for decrypt output)
            if (transaction.boundParams.commitmentCiphertext.length != transaction.commitments.length - 1) {
                return (false, "Invalid Note Ciphertext Array Length");
            }

            bytes32 hash;

            if (transaction.boundParams.decrypt == DecryptType.REDIRECT) {
                hash = hashCommitment(
                    CommitmentPreimage({
                        npk: bytes32(uint256(uint160(msg.sender))),
                        token: transaction.decryptPreimage.token,
                        value: transaction.decryptPreimage.value
                    })
                );
            } else {
                hash = hashCommitment(transaction.decryptPreimage);
            }

            if (hash != transaction.commitments[transaction.commitments.length - 1]) {
                return (false, "Invalid Withdraw Note");
            }
        } else {
            if (transaction.boundParams.commitmentCiphertext.length != transaction.commitments.length) {
                return (false, "Invalid Note Ciphertext Array Length");
            }
        }

        if (!Verifier.verify(transaction)) {
            return (false, "Invalid Snark Proof");
        }

        return (true, "");
    }

    /// @notice Get base and fee amount
    /// @param amount - Amount to calculate for
    /// @param isInclusive - Whether the amount passed in is inclusive of the fee
    /// @param feeBP - Fee basis points
    function getFee(uint136 amount, bool isInclusive, uint120 feeBP) public pure returns (uint120, uint120) {
        uint136 base;
        uint136 fee;

        if (isInclusive) {
            base = amount - (amount * feeBP) / BASIS_POINTS;
            fee = amount - base;
        } else {
            base = amount;
            fee = (BASIS_POINTS * base) / (BASIS_POINTS - feeBP) - base;
        }

        return (uint120(base), uint120(fee));
    }

    /// @notice Gets token ID value from tokenData
    /// @param tokenData - The token data
    function getTokenID(TokenData memory tokenData) public pure returns (bytes32) {
        if (tokenData.tokenType == TokenType.ERC20) {
            return bytes32(uint256(uint160(tokenData.tokenAddress)));
        }

        return bytes32(uint256(keccak256(abi.encode(tokenData))) % SNARK_SCALAR_FIELD);
    }

    /// @notice Hashes a commitment
    /// @param commitmentPreimage - Note to validate
    function hashCommitment(CommitmentPreimage memory commitmentPreimage) public pure returns (bytes32) {
        return
            PoseidonT4.poseidon(
                [
                    commitmentPreimage.npk,
                    getTokenID(commitmentPreimage.token),
                    bytes32(uint256(commitmentPreimage.value))
                ]
            );
    }

    /// @notice Sums number commitments in transaction batch
    /// @param transactions - Transaction batch
    function sumCommitments(Transaction[] calldata transactions) public pure returns (uint256) {
        uint256 length = transactions.length;
        uint256 commitments = 0;

        for (uint256 transactionIter = 0; transactionIter < length; ++transactionIter) {
            commitments += transactions[transactionIter].boundParams.commitmentCiphertext.length;
        }

        return commitments;
    }

    /// @dev Transfers tokens to contract and adjusts preimage with fee values
    /// @param note - Note to process
    /// @return adjusted Note, fee
    function _processEncrypt(CommitmentPreimage calldata note) internal returns (CommitmentPreimage memory, uint256) {
        (bool valid, string memory reason) = validateCommitmentPreimage(note);

        if (!valid) {
            revert InvalidCommitment(reason);
        }

        CommitmentPreimage memory adjustedNote;
        uint256 treasuryFee;

        if (note.token.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(address(uint160(note.token.tokenAddress)));
            (uint120 base, uint120 fee) = getFee(note.value, true, encryptFeeBps);
            treasuryFee = fee;

            adjustedNote = CommitmentPreimage({ npk: note.npk, value: base, token: note.token });
            uint256 balanceBefore = token.balanceOf(address(this));

            token.safeTransferFrom(address(msg.sender), address(this), base);
            uint256 balanceAfter = token.balanceOf(address(this));

            if (balanceAfter - balanceBefore != base) {
                revert ERC20TokenTransferFailed();
            }

            token.safeTransferFrom(address(msg.sender), treasury, fee);
        } else if (note.token.tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(address(uint160(note.token.tokenAddress)));
            treasuryFee = 0;
            adjustedNote = note;
            tokenIDMapping[getTokenID(note.token)] = note.token;

            token.transferFrom(address(msg.sender), address(this), note.token.tokenSubID);

            if (token.ownerOf(note.token.tokenSubID) != address(this)) {
                revert ERC721TokenTransferFailed();
            }
        } else {
            revert UnsupportedToken();
        }

        return (adjustedNote, treasuryFee);
    }

    /// @dev Checks if a recipient address is eligible for an decrypt
    /// @param recipient - address to process
    function _validateDecrypt(address recipient) internal view returns (bool, string memory) {
        if (protection.isSanctioned(recipient)) {
            return (false, "Transfer to Sanctioned Address");
        }

        return (true, "");
    }

    /// @dev Transfers tokens to contract and adjusts preimage with fee values
    /// @param note - Note to process
    function _processDecrypt(CommitmentPreimage calldata note) internal {
        address recipient = address(uint160(uint256(note.npk)));
        (bool valid, string memory reason) = _validateDecrypt(recipient);

        if (!valid) {
            revert InvalidDecrypt(reason);
        }

        if (note.token.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(address(uint160(note.token.tokenAddress)));

            if (recipient != treasury) {
                (uint120 base, uint120 fee) = getFee(note.value, true, decryptFeeBps);
                token.safeTransfer(recipient, base);
                token.safeTransfer(treasury, fee);

                emit Decrypt({ to: recipient, token: note.token, amount: base, fee: fee });

                return;
            }
            token.safeTransfer(recipient, note.value);

            emit Decrypt({ to: recipient, token: note.token, amount: 0, fee: note.value });
        } else if (note.token.tokenType == TokenType.ERC721) {
            IERC721 token = IERC721(address(uint160(note.token.tokenAddress)));
            token.transferFrom(address(this), recipient, note.token.tokenSubID);

            emit Decrypt({ to: recipient, token: note.token, amount: 1, fee: 0 });
        } else {
            revert UnsupportedToken();
        }
    }

    /// @dev Accumulates transaction fields and nullifies nullifiers
    /// @param transaction - transaction to process
    /// @param commitments - commitments accumulator
    /// @param commitmentsStartOffset - number of commitments already in the accumulator
    /// @param ciphertext - commitment ciphertext accumulator, count will be identical to commitments accumulator
    /// @return New nullifier start offset, new commitments start offset
    function _processTransfer(
        Transaction calldata transaction,
        bytes32[] memory commitments,
        uint256 commitmentsStartOffset,
        CommitmentCiphertext[] memory ciphertext
    ) internal returns (uint256) {
        uint256 nullifierCount = transaction.nullifiers.length;
        for (uint256 nullifierIter = 0; nullifierIter < nullifierCount; ++nullifierIter) {
            if (Commitments.nullifiers[transaction.boundParams.treeNumber][transaction.nullifiers[nullifierIter]]) {
                revert NoteAlreadySpent();
            }

            Commitments.nullifiers[transaction.boundParams.treeNumber][transaction.nullifiers[nullifierIter]] = true;
        }

        emit Nullified({ treeNumber: transaction.boundParams.treeNumber, nullifier: transaction.nullifiers });

        uint256 commitmentCount = transaction.boundParams.commitmentCiphertext.length;
        for (uint256 commitmentsIter = 0; commitmentsIter < commitmentCount; ++commitmentsIter) {
            commitments[commitmentsStartOffset + commitmentsIter] = transaction.commitments[commitmentsIter];
            ciphertext[commitmentsStartOffset + commitmentsIter] = transaction.boundParams.commitmentCiphertext[
                commitmentsIter
            ];
        }

        return commitmentsStartOffset + commitmentCount;
    }

    /// @dev Internal logic for changing Protection list
    /// @param newProtection - Address of the new Protection list
    function _changeProtection(Protection newProtection) private {
        if (address(newProtection) == address(0)) {
            revert InvalidAddress();
        }

        if (protection == newProtection) {
            revert IdenticalValue();
        }

        protection = newProtection;

        emit ProtectionChange({ protection: newProtection });
    }

    uint256[50] private _gap;
}
