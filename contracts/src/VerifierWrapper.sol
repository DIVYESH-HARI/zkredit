// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IVerifier.sol";
import "./Verifier.sol";

/**
 * @title VerifierWrapper
 * @notice Wraps the EZKL-generated Halo2Verifier to implement IVerifier interface
 */
contract VerifierWrapper is IVerifier {
    Halo2Verifier public immutable halo2Verifier;

    constructor(address _halo2Verifier) {
        halo2Verifier = Halo2Verifier(_halo2Verifier);
    }

    /**
     * @notice Verifies a ZK proof by delegating to Halo2Verifier
     * @param proof The serialized proof bytes
     * @param instances Public instance values for the circuit
     * @return True if the proof is valid
     */
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) external override returns (bool) {
        return halo2Verifier.verifyProof(proof, instances);
    }
}
