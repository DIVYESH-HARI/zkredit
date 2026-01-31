// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IVerifier.sol";

/**
 * @title MockVerifier
 * @notice Mock implementation of ZK verifier for testing
 * @dev Always returns a configurable result for testing different scenarios
 */
contract MockVerifier is IVerifier {
    /// @notice Whether to return true or false for proof verification
    bool public shouldPass;
    
    /// @notice Count of verification calls (for testing)
    uint256 public verifyCallCount;
    
    /// @notice Last instances received (for testing)
    uint256[] public lastInstances;
    
    /// @notice Last proof bytes received (for testing)
    bytes public lastProof;
    
    constructor(bool _shouldPass) {
        shouldPass = _shouldPass;
    }
    
    /**
     * @notice Mock verification - returns configured result
     */
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) external override returns (bool) {
        verifyCallCount++;
        lastProof = proof;
        delete lastInstances;
        for (uint256 i = 0; i < instances.length; i++) {
            lastInstances.push(instances[i]);
        }
        return shouldPass;
    }
    
    /**
     * @notice Toggle the verification result
     */
    function setShouldPass(bool _shouldPass) external {
        shouldPass = _shouldPass;
    }
}
