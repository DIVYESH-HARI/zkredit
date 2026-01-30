// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ConstraintRegistry
 * @author ZKredit Team
 * @notice Stores and validates lending constraints for ZK-based credit scoring
 * @dev Transparent rules that can be publicly audited
 * 
 * Security Considerations:
 * - Only owner can update constraints (prevents unauthorized changes)
 * - All constraint changes emit events for transparency
 * - Constraints are public for auditability
 */
contract ConstraintRegistry {
    /// @notice Lending constraint parameters
    struct Constraints {
        uint256 minIncome;              // Minimum annual income in USD (scaled by 1e18)
        uint256 maxDTI;                 // Maximum debt-to-income ratio in basis points (3000 = 30%)
        uint256 minCreditScore;         // Minimum credit score (0-100 scale)
        uint256 collateralRatioGood;    // Collateral % for scores >= 80 (e.g., 120 = 120%)
        uint256 collateralRatioStandard; // Collateral % for scores < 80 (e.g., 150 = 150%)
    }
    
    /// @notice Currently active lending constraints
    Constraints public activeConstraints;
    
    /// @notice Owner address (can update constraints)
    address public owner;
    
    /// @notice Emitted when constraints are updated
    /// @param constraints The new constraint values
    /// @param updatedBy Address that made the update
    /// @param timestamp Block timestamp of the update
    event ConstraintsUpdated(
        uint256 minIncome,
        uint256 maxDTI,
        uint256 minCreditScore,
        uint256 collateralRatioGood,
        uint256 collateralRatioStandard,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /// @dev Restricts function access to contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "ConstraintRegistry: caller is not owner");
        _;
    }
    
    /// @notice Initializes with default safe constraints
    constructor() {
        owner = msg.sender;
        
        // Default safe constraints
        activeConstraints = Constraints({
            minIncome: 5000 * 1e18,      // $5,000 minimum annual income
            maxDTI: 3000,                 // 30% max debt-to-income
            minCreditScore: 70,           // 70/100 minimum score
            collateralRatioGood: 120,     // 120% for good credit
            collateralRatioStandard: 150  // 150% for standard credit
        });
        
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @notice Checks if given parameters meet the lending constraints
     * @param income Annual income in USD (scaled by 1e18)
     * @param dti Debt-to-income ratio in basis points
     * @param creditScore Credit score (0-100 scale)
     * @return True if all constraints are satisfied
     */
    function checkConstraints(
        uint256 income,
        uint256 dti,
        uint256 creditScore
    ) external view returns (bool) {
        return income >= activeConstraints.minIncome &&
               dti <= activeConstraints.maxDTI &&
               creditScore >= activeConstraints.minCreditScore;
    }
    
    /**
     * @notice Updates the active lending constraints
     * @param _minIncome New minimum income requirement
     * @param _maxDTI New maximum DTI ratio
     * @param _minCreditScore New minimum credit score
     * @param _collateralRatioGood New collateral ratio for good credit
     * @param _collateralRatioStandard New collateral ratio for standard credit
     * 
     * Requirements:
     * - Caller must be owner
     * - Collateral ratios must be >= 100%
     * - maxDTI must be <= 10000 (100%)
     * - minCreditScore must be <= 100
     */
    function updateConstraints(
        uint256 _minIncome,
        uint256 _maxDTI,
        uint256 _minCreditScore,
        uint256 _collateralRatioGood,
        uint256 _collateralRatioStandard
    ) external onlyOwner {
        require(_maxDTI <= 10000, "ConstraintRegistry: DTI cannot exceed 100%");
        require(_minCreditScore <= 100, "ConstraintRegistry: score cannot exceed 100");
        require(_collateralRatioGood >= 100, "ConstraintRegistry: ratio must be >= 100%");
        require(_collateralRatioStandard >= 100, "ConstraintRegistry: ratio must be >= 100%");
        require(
            _collateralRatioStandard >= _collateralRatioGood,
            "ConstraintRegistry: standard ratio must be >= good ratio"
        );
        
        activeConstraints = Constraints({
            minIncome: _minIncome,
            maxDTI: _maxDTI,
            minCreditScore: _minCreditScore,
            collateralRatioGood: _collateralRatioGood,
            collateralRatioStandard: _collateralRatioStandard
        });
        
        emit ConstraintsUpdated(
            _minIncome,
            _maxDTI,
            _minCreditScore,
            _collateralRatioGood,
            _collateralRatioStandard,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Transfers ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ConstraintRegistry: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @notice Gets the collateral ratio for a given credit score
     * @param creditScore The borrower's credit score
     * @return The required collateral ratio percentage
     */
    function getCollateralRatio(uint256 creditScore) external view returns (uint256) {
        if (creditScore >= 80) {
            return activeConstraints.collateralRatioGood;
        }
        return activeConstraints.collateralRatioStandard;
    }
}
