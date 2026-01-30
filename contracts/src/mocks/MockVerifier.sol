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
    
    /// @notice Last public signals received (for testing)
    uint256[] public lastPubSignals;
    
    constructor(bool _shouldPass) {
        shouldPass = _shouldPass;
    }
    
    /**
     * @notice Mock verification - returns configured result
     */
    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[] calldata _pubSignals
    ) external override returns (bool) {
        verifyCallCount++;
        delete lastPubSignals;
        for (uint256 i = 0; i < _pubSignals.length; i++) {
            lastPubSignals.push(_pubSignals[i]);
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
