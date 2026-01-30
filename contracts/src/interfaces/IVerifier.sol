// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVerifier
 * @notice Interface for EZKL-generated ZK proof verifier
 * @dev This interface matches the signature of EZKL's auto-generated Verifier contract
 */
interface IVerifier {
    /**
     * @notice Verifies a ZK proof
     * @param _pA First part of the proof (G1 point)
     * @param _pB Second part of the proof (G2 point)
     * @param _pC Third part of the proof (G1 point)
     * @param _pubSignals Public signals/inputs to the circuit
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[] calldata _pubSignals
    ) external view returns (bool);
}
