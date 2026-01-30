// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ModelRegistry
 * @author ZKredit Team
 * @notice Stores committed model hashes with versioning for ZK-ML verification
 * @dev Immutable model commitment ensures users can verify which model was used for scoring
 * 
 * Security Considerations:
 * - Only owner can commit new models (prevents malicious model injection)
 * - Model history is preserved for auditing
 * - Hash verification is gas-efficient (single storage read)
 */
contract ModelRegistry {
    /// @notice Current active model hash (keccak256 of ONNX file)
    bytes32 public currentModelHash;
    
    /// @notice Current model version (increments with each commit)
    uint256 public modelVersion;
    
    /// @notice Owner address (can commit new models)
    address public owner;
    
    /// @notice Historical record of all model hashes by version
    mapping(uint256 => bytes32) public modelHistory;
    
    /// @notice Emitted when a new model is committed
    /// @param newHash The keccak256 hash of the new model
    /// @param version The new version number
    /// @param timestamp Block timestamp of the commit
    event ModelUpdated(bytes32 indexed newHash, uint256 indexed version, uint256 timestamp);
    
    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /// @dev Restricts function access to contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "ModelRegistry: caller is not owner");
        _;
    }
    
    /// @notice Initializes the registry with deployer as owner
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @notice Commits a new model hash to the registry
     * @dev Increments version and stores hash in history
     * @param _modelHash The keccak256 hash of the ONNX model file
     * 
     * Requirements:
     * - Caller must be owner
     * - Model hash should be non-zero (not enforced but recommended)
     */
    function commitModel(bytes32 _modelHash) external onlyOwner {
        require(_modelHash != bytes32(0), "ModelRegistry: invalid model hash");
        
        modelVersion++;
        currentModelHash = _modelHash;
        modelHistory[modelVersion] = _modelHash;
        
        emit ModelUpdated(_modelHash, modelVersion, block.timestamp);
    }
    
    /**
     * @notice Verifies if a given hash matches the current model
     * @param _hash The hash to verify
     * @return True if hash matches current model, false otherwise
     */
    function verifyModelHash(bytes32 _hash) external view returns (bool) {
        return _hash == currentModelHash;
    }
    
    /**
     * @notice Transfers ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ModelRegistry: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @notice Gets model hash for a specific version
     * @param _version The version number to query
     * @return The model hash for that version
     */
    function getModelHashByVersion(uint256 _version) external view returns (bytes32) {
        require(_version > 0 && _version <= modelVersion, "ModelRegistry: invalid version");
        return modelHistory[_version];
    }
}
