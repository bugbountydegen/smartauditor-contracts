// SPDX-License-Identifier: UNLICENSED
// Based on code from MACI:
// (https://github.com/appliedzkp/maci/blob/7f36a915244a6e8f98bacfe255f8bd44193e7919/contracts/sol/IncrementalMerkleTree.sol)
pragma solidity 0.8.23;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { SNARK_SCALAR_FIELD } from "./Globals.sol";
import { PoseidonT3 } from "./PoseidonT3.sol";

/// @title Commitments
/// @author DOP Team
/// @notice Batch Incremental Merkle Tree for commitments
/// @dev Publicly accessible functions to be put in DOPLogic. Relevant external contract calls should be in those functions, not here
contract Commitments is Initializable {
    // The tree depth
    uint256 internal constant _TREE_DEPTH = 16;

    // Tree zero value
    bytes32 public constant ZERO_VALUE = bytes32(uint256(keccak256("DOP")) % SNARK_SCALAR_FIELD);

    // The Merkle root
    bytes32 public merkleRoot;

    // Store new tree root to quickly migrate to a new tree
    bytes32 private _newMerkleRoot;

    // Next leaf index (number of inserted leaves in the current tree)
    uint256 public nextLeafIndex;

    // Tree number
    uint256 public treeNumber;

    // Commitment nullifiers (tree number -> nullifier -> seen)
    mapping(uint256 => mapping(bytes32 => bool)) public nullifiers;

    // The Merkle path to the leftmost leaf upon initialization. It SHOULD NOT be modified after it has been set by the initialize function.
    // Caching these values is essential to efficient appends
    bytes32[_TREE_DEPTH] public zeros;

    // Right-most elements at each level. Used for efficient updates of the merkle tree
    bytes32[_TREE_DEPTH] private _rightMostLeafAtLevel;

    // Whether the contract has already seen a particular Merkle tree root
    // treeNumber -> root -> seen
    mapping(uint256 => mapping(bytes32 => bool)) public rootHistory;

    /// @notice Gets tree number that new commitments will get inserted to
    /// @param newCommitments number of new commitments
    /// @return treeNumber, startingIndex
    function getInsertionTreeNumberAndStartingIndex(uint256 newCommitments) public view returns (uint256, uint256) {
        if ((nextLeafIndex + newCommitments) > (2 ** _TREE_DEPTH)) {
            return (treeNumber + 1, 0);
        }

        return (treeNumber, nextLeafIndex);
    }

    /// @notice Hash 2 uint256 values
    /// @param left Left side of hash
    /// @param right Right side of hash
    /// @return hash result
    function hashLeftRight(bytes32 left, bytes32 right) public pure returns (bytes32) {
        return PoseidonT3.poseidon([left, right]);
    }

    /// @dev Calculates initial values for Merkle Tree
    function _initializeCommitments() internal onlyInitializing {
        zeros[0] = ZERO_VALUE;
        bytes32 currentZero = ZERO_VALUE;

        for (uint256 i = 0; i < _TREE_DEPTH; ++i) {
            zeros[i] = currentZero;
            _rightMostLeafAtLevel[i] = currentZero;
            currentZero = hashLeftRight(currentZero, currentZero);
        }
        _newMerkleRoot = merkleRoot = currentZero;
        rootHistory[treeNumber][currentZero] = true;
    }

    /// @dev Calculates initial values for Merkle Tree
    /// @dev Insert leaves into the current merkle tree
    /// Note: this function INTENTIONALLY causes side effects to save on gas. leafHashes and count should never be reused.
    /// @param leaves array of leaf hashes to be added to the merkle tree
    function _addLeaves(bytes32[] memory leaves) internal {
        uint256 leafCount = leaves.length;
        if (leafCount == 0) {
            return;
        }
        if ((nextLeafIndex + leafCount) > (2 ** _TREE_DEPTH)) {
            _startNewTree();
        }
        uint256 insertionIndex = nextLeafIndex;
        nextLeafIndex += leafCount;
        uint256 nextLevelIndex;
        uint256 nextLevelStartingIndex;

        for (uint256 level = 0; level < _TREE_DEPTH; ++level) {
            nextLevelStartingIndex = insertionIndex >> 1;
            uint256 insertionElement = 0;

            if (insertionIndex % 2 == 1) {
                nextLevelIndex = (insertionIndex >> 1) - nextLevelStartingIndex;
                leaves[nextLevelIndex] = hashLeftRight(_rightMostLeafAtLevel[level], leaves[insertionElement]);
                ++insertionElement;
                ++insertionIndex;
            }

            for (insertionElement; insertionElement < leafCount; insertionElement += 2) {
                bytes32 right;

                if (insertionElement < leafCount - 1) {
                    right = leaves[insertionElement + 1];
                } else {
                    right = zeros[level];
                }

                if (insertionElement == leafCount - 1 || insertionElement == leafCount - 2) {
                    _rightMostLeafAtLevel[level] = leaves[insertionElement];
                }

                nextLevelIndex = (insertionIndex >> 1) - nextLevelStartingIndex;
                leaves[nextLevelIndex] = hashLeftRight(leaves[insertionElement], right);
                insertionIndex += 2;
            }
            insertionIndex = nextLevelStartingIndex;
            leafCount = nextLevelIndex + 1;
        }
        merkleRoot = leaves[0];
        rootHistory[treeNumber][merkleRoot] = true;
    }

    /// @dev Creates new merkle tree
    function _startNewTree() internal {
        merkleRoot = _newMerkleRoot;
        nextLeafIndex = 0;
        ++treeNumber;
    }

    uint256[50] private _gap;
}
