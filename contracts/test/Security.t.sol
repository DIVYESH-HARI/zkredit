// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ZKreditLendingPool.sol";
import "../src/ModelRegistry.sol";
import "../src/ConstraintRegistry.sol";
import "../src/mocks/MockVerifier.sol";

/**
 * @title SecurityTest
 * @notice Comprehensive security test suite for ZKredit lending protocol
 * @dev Tests all "Judge's Corner" attack vectors:
 *      1. Replay Attack - Reusing valid proofs
 *      2. GIGO Attack - Garbage In, Garbage Out (fake data)
 *      3. Model Tampering - Using different model weights
 *      4. Constraint Bypass - Attempting to bypass DTI/income checks
 *      5. Collateral Manipulation - Submitting insufficient collateral
 */
contract SecurityTest is Test {
    ZKreditLendingPool public pool;
    ModelRegistry public registry;
    ConstraintRegistry public constraints;
    MockVerifier public verifier;
    
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public attacker = address(0x3);
    address public liquidityProvider = address(0x4);
    
    // Valid model hash for testing
    bytes32 public constant VALID_MODEL_HASH = keccak256("credit_scoring_model_v1");
    bytes32 public constant FAKE_MODEL_HASH = keccak256("tampered_model");
    
    // Credit score thresholds
    uint256 public constant EXCELLENT_CREDIT = 85;
    uint256 public constant GOOD_CREDIT = 70;
    uint256 public constant POOR_CREDIT = 40;
    
    event LoanApproved(address indexed borrower, uint256 amount, uint256 collateral, uint256 collateralRatio, uint256 creditScore, uint256 timestamp);
    event ReplayAttempt(address indexed attacker, bytes32 proofHash);
    
    function setUp() public {
        // Deploy mock verifier that accepts all proofs
        verifier = new MockVerifier(true);
        
        // Deploy model registry and commit valid model hash
        registry = new ModelRegistry();
        registry.commitModel(VALID_MODEL_HASH);
        
        // Deploy constraint registry (uses defaults from constructor)
        // Default: minIncome: 5000 * 1e18, maxDTI: 3000 (30%), minCreditScore: 70
        constraints = new ConstraintRegistry();
        
        // Update constraints to match Phase 5 criteria
        // minIncome: 3000, maxDTI: 3000 (30%), minCreditScore: 50
        constraints.updateConstraints(
            3000 * 1e18,  // minIncome
            3000,         // maxDTI (30%) - per Phase 5 criteria
            50,           // minCreditScore
            120,          // collateralRatioGood
            150           // collateralRatioStandard
        );
        
        // Deploy lending pool
        pool = new ZKreditLendingPool(
            address(verifier),
            address(registry),
            address(constraints)
        );
        
        // Fund the pool with liquidity
        vm.deal(liquidityProvider, 100 ether);
        vm.prank(liquidityProvider);
        pool.depositLiquidity{value: 50 ether}();
        
        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(attacker, 10 ether);
    }
    
    // ============================================
    // Helper Functions
    // ============================================
    
    /**
     * @dev Generates mock proof components for testing
     *      In production, these would be actual EZKL-generated proofs
     */
    function generateMockProof(uint256 seed) internal pure returns (
        uint256[2] memory pA,
        uint256[2][2] memory pB,
        uint256[2] memory pC
    ) {
        pA = [uint256(keccak256(abi.encode(seed, "pA0"))), uint256(keccak256(abi.encode(seed, "pA1")))];
        pB = [
            [uint256(keccak256(abi.encode(seed, "pB00"))), uint256(keccak256(abi.encode(seed, "pB01")))],
            [uint256(keccak256(abi.encode(seed, "pB10"))), uint256(keccak256(abi.encode(seed, "pB11")))]
        ];
        pC = [uint256(keccak256(abi.encode(seed, "pC0"))), uint256(keccak256(abi.encode(seed, "pC1")))];
    }
    
    /**
     * @dev Creates public signals array for loan request
     * @param income Monthly income in wei-like format
     * @param dti Debt-to-income ratio in basis points (10000 = 100%)
     * @param modelHash Hash of the ML model used
     */
    function createPublicSignals(
        uint256 income,
        uint256 dti,
        bytes32 modelHash
    ) internal pure returns (uint256[] memory) {
        uint256[] memory signals = new uint256[](3);
        signals[0] = income;
        signals[1] = dti;
        signals[2] = uint256(modelHash);
        return signals;
    }
    
    // ============================================
    // ATTACK VECTOR 1: Replay Attack Protection
    // Judge's Corner Risk: Attacker reuses someone else's valid proof
    // ============================================
    
    /**
     * @notice Tests that the same proof cannot be used twice (anti-replay)
     * @dev This prevents attackers from:
     *      1. Monitoring mempool for valid proofs
     *      2. Front-running or replaying transactions
     *      3. Using the same proof for multiple loans
     */
    function test_ReplayAttack_SameUserCannotReuseProof() public {
        // Generate valid proof for Alice
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(1);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Alice successfully uses the proof
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        // Alice tries to reuse the same proof for another loan (after repaying)
        // First repay the loan
        vm.prank(alice);
        pool.repayLoan{value: 1 ether}();
        
        // Now try to reuse - should fail
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: proof already used");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests that attacker cannot steal and replay another user's proof
     */
    function test_ReplayAttack_AttackerCannotStealProof() public {
        // Generate valid proof
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(2);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Alice uses her proof first
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        // Attacker tries to replay the exact same proof
        vm.prank(attacker);
        vm.expectRevert("ZKreditLendingPool: proof already used");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    // ============================================
    // ATTACK VECTOR 2: GIGO (Garbage In, Garbage Out)
    // Judge's Corner Risk: Fake data with valid proof structure
    // ============================================
    
    /**
     * @notice Tests rejection of proofs with zero income
     * @dev GIGO Attack: Attacker creates valid proof format but with fake income=0
     */
    function test_GIGO_ZeroIncomeRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(10);
        
        // GIGO: Valid proof structure but income = 0
        uint256[] memory pubSignals = createPublicSignals(0, 2500, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests rejection of proofs with income below minimum threshold
     */
    function test_GIGO_InsufficientIncomeRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(11);
        
        // GIGO: Income below the 3000 minimum
        uint256[] memory pubSignals = createPublicSignals(1000 * 1e18, 2500, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests that extremely high fake income is caught by other constraints
     */
    function test_GIGO_FakeHighIncomeWithBadDTI() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(12);
        
        // GIGO: Fake extremely high income but bad DTI
        // Even with high income, if DTI is bad, should fail
        uint256[] memory pubSignals = createPublicSignals(1000000 * 1e18, 5000, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    // ============================================
    // ATTACK VECTOR 3: Model Tampering
    // Judge's Corner Risk: Using a different (rigged) ML model
    // ============================================
    
    /**
     * @notice Tests rejection of proofs generated with unauthorized model
     * @dev Model Tampering: Attacker uses modified model that always outputs high score
     */
    function test_ModelTampering_WrongHashRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(20);
        
        // Use tampered/unauthorized model hash
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, FAKE_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: model hash mismatch");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests rejection of zero model hash
     */
    function test_ModelTampering_ZeroHashRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(21);
        
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, bytes32(0));
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: model hash mismatch");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests that only registered models are accepted
     */
    function test_ModelTampering_OnlyRegisteredModelsAccepted() public {
        // Commit a new model hash
        bytes32 newModelHash = keccak256("credit_scoring_model_v2");
        registry.commitModel(newModelHash);
        
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(22);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, newModelHash);
        
        // Should succeed with newly registered model
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        (,uint256 amount,,,,,) = pool.activeLoans(alice);
        assertTrue(amount > 0, "Loan should be approved");
    }
    
    // ============================================
    // ATTACK VECTOR 4: Constraint Layer Bypass
    // Judge's Corner Risk: Manipulating DTI or other constraints
    // ============================================
    
    /**
     * @notice Tests rejection of proofs with DTI above maximum threshold
     */
    function test_ConstraintBypass_HighDTIRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(30);
        
        // DTI = 100% (10000 basis points) - way above 40% limit
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 10000, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests rejection of DTI > 30% per Phase 5 criteria
     * @dev GIGO Test: DTI of 35% should be rejected (limit is 30%)
     */
    function test_GIGO_DTIAbove30PercentRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(33);
        
        // DTI = 35% (3500 basis points) - above 30% limit
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 3500, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests borderline DTI (exactly at 30% limit)
     */
    function test_ConstraintBypass_BorderlineDTIAccepted() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(31);
        
        // DTI = exactly 30% (3000 basis points) - at the limit
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 3000, VALID_MODEL_HASH);
        
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        (,uint256 amount,,,,,) = pool.activeLoans(alice);
        assertTrue(amount > 0, "Borderline DTI should be accepted");
    }
    
    /**
     * @notice Tests rejection of low credit scores
     */
    function test_ConstraintBypass_LowCreditScoreRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(32);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Credit score below minimum (50)
        vm.prank(bob);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        pool.requestLoan{value: 1.5 ether}(1 ether, 30, pA, pB, pC, pubSignals);
    }
    
    // ============================================
    // ATTACK VECTOR 5: Collateral Manipulation
    // Judge's Corner Risk: Submitting insufficient collateral
    // ============================================
    
    /**
     * @notice Tests rejection of insufficient collateral for excellent credit
     */
    function test_CollateralManipulation_InsufficientCollateralRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(40);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Try to submit only 100% collateral when 120% is required for score 85
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: insufficient collateral");
        pool.requestLoan{value: 1 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests correct collateral ratio for excellent credit (120%)
     */
    function test_CollateralRatio_ExcellentCredit120Percent() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(41);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Exactly 120% collateral for excellent credit
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        (,,uint256 collateral,,,,) = pool.activeLoans(alice);
        assertEq(collateral, 1.2 ether, "Collateral should be 1.2 ETH");
    }
    
    /**
     * @notice Tests correct collateral ratio for standard credit (150%)
     */
    function test_CollateralRatio_StandardCredit150Percent() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(42);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Credit score 55 (below 80, so needs 150%)
        vm.prank(alice);
        pool.requestLoan{value: 1.5 ether}(1 ether, 55, pA, pB, pC, pubSignals);
        
        (,,uint256 collateral,,,,) = pool.activeLoans(alice);
        assertEq(collateral, 1.5 ether, "Collateral should be 1.5 ETH");
    }
    
    // ============================================
    // Additional Security Tests
    // ============================================
    
    /**
     * @notice Tests that empty public signals array is rejected
     */
    function test_EmptyPublicSignalsRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(50);
        uint256[] memory emptySignals = new uint256[](0);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: insufficient public signals");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, emptySignals);
    }
    
    /**
     * @notice Tests that zero loan amount is rejected
     */
    function test_ZeroLoanAmountRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(51);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: loan amount must be > 0");
        pool.requestLoan{value: 0}(0, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests that user cannot have multiple active loans
     */
    function test_MultipleLoansRejected() public {
        (uint256[2] memory pA1, uint256[2][2] memory pB1, uint256[2] memory pC1) = generateMockProof(52);
        (uint256[2] memory pA2, uint256[2][2] memory pB2, uint256[2] memory pC2) = generateMockProof(53);
        uint256[] memory pubSignals1 = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        uint256[] memory pubSignals2 = createPublicSignals(9000 * 1e18, 2000, VALID_MODEL_HASH);
        
        // First loan succeeds
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA1, pB1, pC1, pubSignals1);
        
        // Second loan should fail
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: existing loan active");
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA2, pB2, pC2, pubSignals2);
    }
    
    /**
     * @notice Tests pool liquidity check
     */
    function test_InsufficientPoolLiquidityRejected() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(54);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Give alice enough ETH for the collateral
        vm.deal(alice, 200 ether);
        
        // Try to borrow more than pool has (pool has 50 ETH)
        vm.prank(alice);
        vm.expectRevert("ZKreditLendingPool: insufficient pool liquidity");
        pool.requestLoan{value: 120 ether}(100 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
    }
    
    /**
     * @notice Tests that proof hash is correctly computed
     */
    function test_ProofHashComputation() public {
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) = generateMockProof(55);
        uint256[] memory pubSignals = createPublicSignals(8000 * 1e18, 2500, VALID_MODEL_HASH);
        
        // Compute expected hash
        bytes32 expectedHash = keccak256(abi.encodePacked(pA, pB, pC, pubSignals));
        
        // Submit loan
        vm.prank(alice);
        pool.requestLoan{value: 1.2 ether}(1 ether, EXCELLENT_CREDIT, pA, pB, pC, pubSignals);
        
        // Verify the proof is marked as used
        assertTrue(pool.isProofUsed(expectedHash), "Proof should be marked as used");
    }
}
