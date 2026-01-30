// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IVerifier.sol";
import "./ModelRegistry.sol";
import "./ConstraintRegistry.sol";

/**
 * @title ZKreditLendingPool
 * @author ZKredit Team
 * @notice Main lending pool that integrates ZK proof verification with on-chain constraints
 * @dev Implements privacy-preserving credit scoring with collateralized lending
 * 
 * Security Considerations:
 * - Anti-replay protection prevents proof reuse
 * - Model hash verification prevents model tampering
 * - Constraint checks provide GIGO protection
 * - Collateral requirements protect against defaults
 * - Events provide full auditability
 */
contract ZKreditLendingPool {
    /// @notice The ZK proof verifier contract (EZKL-generated)
    IVerifier public verifier;
    
    /// @notice Registry tracking committed model hashes
    ModelRegistry public modelRegistry;
    
    /// @notice Registry containing lending constraints
    ConstraintRegistry public constraints;
    
    /// @notice Owner address for administrative functions
    address public owner;
    
    /// @notice Loan request/approval record
    struct LoanRequest {
        address borrower;
        uint256 amount;
        uint256 collateral;
        uint256 creditScore;
        bool approved;
        uint256 timestamp;
        uint256 repaymentDeadline;
    }
    
    /// @notice Active loans by borrower address
    mapping(address => LoanRequest) public activeLoans;
    
    /// @notice Tracks used proofs to prevent replay attacks
    mapping(bytes32 => bool) public usedProofs;
    
    /// @notice Total value locked in the pool
    uint256 public totalValueLocked;
    
    /// @notice Pool liquidity available for lending
    uint256 public poolLiquidity;
    
    /// @notice Default loan duration (30 days)
    uint256 public constant LOAN_DURATION = 30 days;
    
    /// @notice Emitted when a loan is approved
    event LoanApproved(
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        uint256 collateralRatio,
        uint256 creditScore,
        uint256 timestamp
    );
    
    /// @notice Emitted when a loan is rejected
    event LoanRejected(
        address indexed borrower,
        string reason,
        uint256 timestamp
    );
    
    /// @notice Emitted when a loan is repaid
    event LoanRepaid(
        address indexed borrower,
        uint256 amount,
        uint256 collateralReturned,
        uint256 timestamp
    );
    
    /// @notice Emitted when collateral is liquidated
    event CollateralLiquidated(
        address indexed borrower,
        uint256 collateralAmount,
        uint256 timestamp
    );
    
    /// @notice Emitted when liquidity is deposited
    event LiquidityDeposited(address indexed depositor, uint256 amount);
    
    /// @notice Emitted when a proof replay is attempted
    event ReplayAttempt(address indexed attacker, bytes32 proofHash);
    
    /// @dev Restricts function access to contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "ZKreditLendingPool: caller is not owner");
        _;
    }
    
    /**
     * @notice Initializes the lending pool with required contract addresses
     * @param _verifier Address of the EZKL verifier contract
     * @param _modelRegistry Address of the ModelRegistry contract
     * @param _constraintRegistry Address of the ConstraintRegistry contract
     */
    constructor(
        address _verifier,
        address _modelRegistry,
        address _constraintRegistry
    ) {
        require(_verifier != address(0), "ZKreditLendingPool: invalid verifier");
        require(_modelRegistry != address(0), "ZKreditLendingPool: invalid model registry");
        require(_constraintRegistry != address(0), "ZKreditLendingPool: invalid constraint registry");
        
        verifier = IVerifier(_verifier);
        modelRegistry = ModelRegistry(_modelRegistry);
        constraints = ConstraintRegistry(_constraintRegistry);
        owner = msg.sender;
    }
    
    /**
     * @notice Allows liquidity providers to deposit funds into the pool
     */
    function depositLiquidity() external payable {
        require(msg.value > 0, "ZKreditLendingPool: must deposit > 0");
        poolLiquidity += msg.value;
        totalValueLocked += msg.value;
        emit LiquidityDeposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Requests a loan using ZK proof of creditworthiness
     * @param _amount Loan amount requested (in wei)
     * @param _creditScore The proven credit score
     * @param _pA First proof component (G1)
     * @param _pB Second proof component (G2)
     * @param _pC Third proof component (G1)
     * @param _pubSignals Public signals: [income, dti, modelHash]
     * 
     * Requirements:
     * - Proof must not have been used before (anti-replay)
     * - ZK proof must verify successfully
     * - Model hash must match committed model
     * - Constraints must be satisfied
     * - Sufficient collateral must be provided
     * - Pool must have sufficient liquidity
     * - Borrower must not have an existing active loan
     */
    function requestLoan(
        uint256 _amount,
        uint256 _creditScore,
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[] calldata _pubSignals
    ) external payable {
        require(_pubSignals.length >= 3, "ZKreditLendingPool: insufficient public signals");
        require(activeLoans[msg.sender].amount == 0, "ZKreditLendingPool: existing loan active");
        require(_amount > 0, "ZKreditLendingPool: loan amount must be > 0");
        require(_amount <= poolLiquidity, "ZKreditLendingPool: insufficient pool liquidity");
        
        // 1. Anti-replay: Check proof hasn't been used
        bytes32 proofHash = keccak256(abi.encodePacked(_pA, _pB, _pC, _pubSignals));
        if (usedProofs[proofHash]) {
            emit ReplayAttempt(msg.sender, proofHash);
            emit LoanRejected(msg.sender, "Proof already used - replay attack detected", block.timestamp);
            revert("ZKreditLendingPool: proof already used");
        }
        usedProofs[proofHash] = true;
        
        // 2. Verify ZK Proof (computation integrity)
        bool proofValid = verifier.verifyProof(_pA, _pB, _pC, _pubSignals);
        if (!proofValid) {
            emit LoanRejected(msg.sender, "Invalid ZK proof", block.timestamp);
            revert("ZKreditLendingPool: invalid ZK proof");
        }
        
        // 3. Verify Model Hash matches committed (prevents model gaming)
        bytes32 proofModelHash = bytes32(_pubSignals[2]);
        if (!modelRegistry.verifyModelHash(proofModelHash)) {
            emit LoanRejected(msg.sender, "Model hash mismatch - potential tampering", block.timestamp);
            revert("ZKreditLendingPool: model hash mismatch");
        }
        
        // 4. Verify Constraints (GIGO protection layer)
        uint256 income = _pubSignals[0];
        uint256 dti = _pubSignals[1];
        if (!constraints.checkConstraints(income, dti, _creditScore)) {
            emit LoanRejected(msg.sender, "Fails constraint checks", block.timestamp);
            revert("ZKreditLendingPool: fails constraint checks");
        }
        
        // 5. Calculate Required Collateral
        uint256 ratio = constraints.getCollateralRatio(_creditScore);
        uint256 requiredCollateral = (_amount * ratio) / 100;
        
        if (msg.value < requiredCollateral) {
            emit LoanRejected(msg.sender, "Insufficient collateral", block.timestamp);
            revert("ZKreditLendingPool: insufficient collateral");
        }
        
        // 6. Record Loan
        activeLoans[msg.sender] = LoanRequest({
            borrower: msg.sender,
            amount: _amount,
            collateral: msg.value,
            creditScore: _creditScore,
            approved: true,
            timestamp: block.timestamp,
            repaymentDeadline: block.timestamp + LOAN_DURATION
        });
        
        // 7. Update pool state
        poolLiquidity -= _amount;
        totalValueLocked += msg.value;
        
        // 8. Transfer Loan Amount
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "ZKreditLendingPool: transfer failed");
        
        emit LoanApproved(msg.sender, _amount, msg.value, ratio, _creditScore, block.timestamp);
    }
    
    /**
     * @notice Repays an active loan and returns collateral
     * 
     * Requirements:
     * - Caller must have an active loan
     * - Must repay full loan amount
     * - Must be before repayment deadline
     */
    function repayLoan() external payable {
        LoanRequest storage loan = activeLoans[msg.sender];
        require(loan.amount > 0, "ZKreditLendingPool: no active loan");
        require(msg.value >= loan.amount, "ZKreditLendingPool: insufficient repayment");
        require(block.timestamp <= loan.repaymentDeadline, "ZKreditLendingPool: loan expired");
        
        uint256 collateralToReturn = loan.collateral;
        uint256 loanAmount = loan.amount;
        
        // Clear loan
        delete activeLoans[msg.sender];
        
        // Update pool state
        poolLiquidity += msg.value;
        totalValueLocked -= collateralToReturn;
        
        // Return collateral
        (bool sent, ) = msg.sender.call{value: collateralToReturn}("");
        require(sent, "ZKreditLendingPool: collateral return failed");
        
        emit LoanRepaid(msg.sender, loanAmount, collateralToReturn, block.timestamp);
    }
    
    /**
     * @notice Liquidates collateral for expired loans
     * @param _borrower Address of the borrower to liquidate
     * 
     * Requirements:
     * - Loan must exist and be expired
     */
    function liquidate(address _borrower) external {
        LoanRequest storage loan = activeLoans[_borrower];
        require(loan.amount > 0, "ZKreditLendingPool: no active loan");
        require(block.timestamp > loan.repaymentDeadline, "ZKreditLendingPool: loan not expired");
        
        uint256 collateralAmount = loan.collateral;
        
        // Clear loan
        delete activeLoans[_borrower];
        
        // Collateral goes to pool liquidity
        poolLiquidity += collateralAmount;
        
        emit CollateralLiquidated(_borrower, collateralAmount, block.timestamp);
    }
    
    /**
     * @notice Gets loan details for a borrower
     * @param _borrower Address to query
     * @return The loan request struct
     */
    function getLoan(address _borrower) external view returns (LoanRequest memory) {
        return activeLoans[_borrower];
    }
    
    /**
     * @notice Checks if a proof has been used
     * @param _proofHash Hash of the proof to check
     * @return True if proof has been used
     */
    function isProofUsed(bytes32 _proofHash) external view returns (bool) {
        return usedProofs[_proofHash];
    }
    
    /**
     * @notice Allows the pool to receive ETH
     */
    receive() external payable {
        poolLiquidity += msg.value;
        totalValueLocked += msg.value;
    }
}
