// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
    uint256 private constant _PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 private constant _PAIRING_INPUT_SIZE = 24;
    uint256 private constant _PAIRING_INPUT_WIDTH = 768; // _PAIRING_INPUT_SIZE * 32

    error InvalidAddition();
    error InvalidInput();
    error InvalidMultiplication();
    error InvalidNegation();
    error InvalidPairing();

    /// @notice Adds 2 G1 points
    /// @return result
    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;

        bool success;
        G1Point memory result;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
        }

        if (!success) {
            revert InvalidAddition();
        }

        return result;
    }

    /// @notice Scalar multiplies two G1 points p, s
    /// @dev The product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
    /// points p.
    /// @return r result
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
        }

        if (!success) {
            revert InvalidMultiplication();
        }
    }

    /// @notice Performs pairing check on points
    /// @dev The result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example,
    /// pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
    /// @return if pairing check passed
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        uint256[_PAIRING_INPUT_SIZE] memory input = [
            a1.x,
            a1.y,
            a2.x[0],
            a2.x[1],
            a2.y[0],
            a2.y[1],
            b1.x,
            b1.y,
            b2.x[0],
            b2.x[1],
            b2.y[0],
            b2.y[1],
            c1.x,
            c1.y,
            c2.x[0],
            c2.x[1],
            c2.y[0],
            c2.y[1],
            d1.x,
            d1.y,
            d2.x[0],
            d2.x[1],
            d2.y[0],
            d2.y[1]
        ];

        uint256[1] memory out;
        bool success;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, _PAIRING_INPUT_WIDTH, out, 0x20)
        }

        if (!success) {
            revert InvalidPairing();
        }

        return out[0] != 0;
    }

    /// @notice Verifies snark proof against proving key
    /// @param vk Verification Key
    /// @param proof snark proof
    /// @param inputs inputs
    function verify(
        VerifyingKey memory vk,
        SnarkProof memory proof,
        uint256[] memory inputs
    ) internal view returns (bool) {
        G1Point memory vkX = G1Point(0, 0);

        uint256 length = inputs.length;
        for (uint256 i = 0; i < length; ++i) {
            if (inputs[i] >= SNARK_SCALAR_FIELD) {
                revert InvalidInput();
            }

            vkX = add(vkX, scalarMul(vk.ic[i + 1], inputs[i]));
        }

        vkX = add(vkX, vk.ic[0]);

        return pairing(negate(proof.a), proof.b, vk.alpha1, vk.beta2, vkX, vk.gamma2, proof.c, vk.delta2);
    }

    /// @notice Computes the negation of point p
    /// @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
    /// @return result
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        }
        // check for valid points y^2 = x^3 +3 % _PRIME_Q
        uint256 rh = mulmod(p.x, p.x, _PRIME_Q); // x^2
        rh = mulmod(rh, p.x, _PRIME_Q); // x^3
        rh = addmod(rh, 3, _PRIME_Q); // x^3 + 3
        uint256 lh = mulmod(p.y, p.y, _PRIME_Q); // y^2

        if (lh != rh) {
            revert InvalidNegation();
        }

        return G1Point(p.x, _PRIME_Q - (p.y % _PRIME_Q));
    }
}
