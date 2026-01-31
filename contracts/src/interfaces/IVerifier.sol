// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVerifier
 * @notice Interface for EZKL-generated ZK proof verifier
 * @dev This interface matches the signature of EZKL's auto-generated Halo2Verifier contract
 */
interface IVerifier {
    /**
     * @notice Verifies a ZK proof
     * @param proof The serialized proof bytes
     * @param instances Public instance values for the circuit
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) external returns (bool);
}
