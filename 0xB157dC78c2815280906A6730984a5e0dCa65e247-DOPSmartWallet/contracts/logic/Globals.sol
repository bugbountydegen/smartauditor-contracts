// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

error AccessDenied();
error ETHTransferFailed();
error IdenticalValue();
error InvalidAddress();
error UnsafeVectors();
error UnsupportedToken();
error InvalidFeeAmount();
error InvalidTransactionData();

uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// Verification bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
// Use 0x000000000000000000000000000000000000dEaD as an alternative known burn address
// https://etherscan.io/address/0x000000000000000000000000000000000000dEaD
address constant VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

bytes32 constant ACCEPT_DOP_RESPONSE = keccak256(abi.encodePacked("Accept DOP Session"));

enum TokenType {
    ERC20,
    ERC721
}

enum DecryptType {
    NONE,
    NORMAL,
    REDIRECT
}

struct EncryptRequest {
    CommitmentPreimage preimage;
    EncryptCiphertext ciphertext;
}

struct TokenData {
    TokenType tokenType;
    address tokenAddress;
    uint256 tokenSubID;
}

struct CommitmentCiphertext {
    // Ciphertext order: IV & tag (16 bytes each), encodedMPK (senderMPK XOR receiverMPK), random & amount (16 bytes each), token
    bytes32[4] ciphertext;
    bytes32 blindedSenderViewingKey;
    bytes32 blindedReceiverViewingKey;
    // Only for sender to decrypt
    bytes annotationData;
    // Added to note ciphertext for decryption
    bytes memo;
}

struct EncryptCiphertext {
    // IV shared, tag, random & IV sender (16 bytes each), receiver viewing public key (32 bytes)
    bytes32[3] encryptedBundle;
    // Public key to generate shared key from
    bytes32 encryptKey;
}

struct BoundParams {
    uint16 treeNumber;
    // Only for type 0 transactions
    uint72 minGasPrice;
    DecryptType decrypt;
    uint64 chainID;
    address adaptContract;
    bytes32 adaptParams;
    // For decrypts do not include an element in ciphertext array
    // NOTE: Ciphertext array length = commitments decrypts
    CommitmentCiphertext[] commitmentCiphertext;
}

struct Transaction {
    SnarkProof proof;
    bytes32 merkleRoot;
    bytes32[] nullifiers;
    bytes32[] commitments;
    BoundParams boundParams;
    CommitmentPreimage decryptPreimage;
}

struct CommitmentPreimage {
    // Poseidon(Poseidon(spending public key, nullifying key), random)
    bytes32 npk;
    // Token field
    TokenData token;
    uint120 value;
}

struct G1Point {
    uint256 x;
    uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
    uint256[2] x;
    uint256[2] y;
}

struct VerifyingKey {
    string artifactsIPFSHash;
    G1Point alpha1;
    G2Point beta2;
    G2Point gamma2;
    G2Point delta2;
    G1Point[] ic;
}

struct SnarkProof {
    G1Point a;
    G2Point b;
    G1Point c;
}
