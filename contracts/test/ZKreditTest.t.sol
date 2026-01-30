// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ModelRegistry.sol";
import "../src/ConstraintRegistry.sol";
import "../src/ZKreditLendingPool.sol";
import "../src/mocks/MockVerifier.sol";

/**
 * @title ZKreditTest
 * @notice Comprehensive test suite for ZKredit contracts
 */
contract ZKreditTest is Test {
    ModelRegistry public modelRegistry;
    ConstraintRegistry public constraintRegistry;
    ZKreditLendingPool public lendingPool;
    MockVerifier public mockVerifier;
    
    address public owner = address(this);
    address public borrower = address(0x1);
    address public attacker = address(0x2);
    
    bytes32 public constant DEMO_MODEL_HASH = keccak256("demo_credit_model_v1.onnx");
    
    // Test proof data (mock values)
    uint256[2] pA = [uint256(1), uint256(2)];
    uint256[2][2] pB = [[uint256(1), uint256(2)], [uint256(3), uint256(4)]];
    uint256[2] pC = [uint256(1), uint256(2)];
    
    function setUp() public {
        // Deploy contracts
        modelRegistry = new ModelRegistry();
        constraintRegistry = new ConstraintRegistry();
        mockVerifier = new MockVerifier(true); // Proofs pass by default
        
        lendingPool = new ZKreditLendingPool(
            address(mockVerifier),
            address(modelRegistry),
            address(constraintRegistry)
        );
        
        // Commit initial model
        modelRegistry.commitModel(DEMO_MODEL_HASH);
        
        // Fund pool with liquidity
        lendingPool.depositLiquidity{value: 100 ether}();
        
        // Fund borrower
        vm.deal(borrower, 10 ether);
        vm.deal(attacker, 10 ether);
    }
    
    // ============ ModelRegistry Tests ============
    
    function testModelCommitFlow() public {
        // Test initial state
        assertEq(modelRegistry.modelVersion(), 1);
        assertEq(modelRegistry.currentModelHash(), DEMO_MODEL_HASH);
        
        // Commit new model
        bytes32 newHash = keccak256("credit_model_v2.onnx");
        modelRegistry.commitModel(newHash);
        
        assertEq(modelRegistry.modelVersion(), 2);
        assertEq(modelRegistry.currentModelHash(), newHash);
        assertEq(modelRegistry.modelHistory(1), DEMO_MODEL_HASH);
        assertEq(modelRegistry.modelHistory(2), newHash);
    }
    
    function testModelHashVerification() public {
        assertTrue(modelRegistry.verifyModelHash(DEMO_MODEL_HASH));
        assertFalse(modelRegistry.verifyModelHash(keccak256("fake_model")));
    }
    
    function testOnlyOwnerCanCommitModel() public {
        vm.prank(borrower);
        vm.expectRevert("ModelRegistry: caller is not owner");
        modelRegistry.commitModel(keccak256("malicious_model"));
    }
    
    function testCannotCommitZeroHash() public {
        vm.expectRevert("ModelRegistry: invalid model hash");
        modelRegistry.commitModel(bytes32(0));
    }
    
    // ============ ConstraintRegistry Tests ============
    
    function testDefaultConstraints() public {
        (
            uint256 minIncome,
            uint256 maxDTI,
            uint256 minCreditScore,
            uint256 collateralRatioGood,
            uint256 collateralRatioStandard
        ) = constraintRegistry.activeConstraints();
        
        assertEq(minIncome, 5000 * 1e18);
        assertEq(maxDTI, 3000);
        assertEq(minCreditScore, 70);
        assertEq(collateralRatioGood, 120);
        assertEq(collateralRatioStandard, 150);
    }
    
    function testConstraintChecking() public {
        // Should pass - meets all requirements
        assertTrue(constraintRegistry.checkConstraints(
            10000 * 1e18, // income: $10k
            2000,         // dti: 20%
            80            // credit score: 80
        ));
        
        // Should fail - income too low
        assertFalse(constraintRegistry.checkConstraints(
            1000 * 1e18,  // income: $1k (below $5k min)
            2000,
            80
        ));
        
        // Should fail - DTI too high
        assertFalse(constraintRegistry.checkConstraints(
            10000 * 1e18,
            4000,         // dti: 40% (above 30% max)
            80
        ));
        
        // Should fail - credit score too low
        assertFalse(constraintRegistry.checkConstraints(
            10000 * 1e18,
            2000,
            50            // score: 50 (below 70 min)
        ));
    }
    
    function testCollateralRatioCalculation() public {
        // Good credit (>= 80) gets 120%
        assertEq(constraintRegistry.getCollateralRatio(80), 120);
        assertEq(constraintRegistry.getCollateralRatio(90), 120);
        
        // Standard credit (< 80) gets 150%
        assertEq(constraintRegistry.getCollateralRatio(79), 150);
        assertEq(constraintRegistry.getCollateralRatio(70), 150);
    }
    
    function testConstraintUpdate() public {
        constraintRegistry.updateConstraints(
            10000 * 1e18, // new min income
            2500,         // new max DTI
            75,           // new min score
            110,          // new good ratio
            140           // new standard ratio
        );
        
        (
            uint256 minIncome,
            uint256 maxDTI,
            uint256 minCreditScore,
            uint256 collateralRatioGood,
            uint256 collateralRatioStandard
        ) = constraintRegistry.activeConstraints();
        
        assertEq(minIncome, 10000 * 1e18);
        assertEq(maxDTI, 2500);
        assertEq(minCreditScore, 75);
        assertEq(collateralRatioGood, 110);
        assertEq(collateralRatioStandard, 140);
    }
    
    // ============ LendingPool Tests ============
    
    function testSuccessfulLoanRequest() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18; // income
        pubSignals[1] = 2000;          // dti
        pubSignals[2] = uint256(DEMO_MODEL_HASH); // model hash
        
        uint256 loanAmount = 1 ether;
        uint256 creditScore = 85;
        uint256 collateral = (loanAmount * 120) / 100; // 120% for good credit
        
        vm.prank(borrower);
        lendingPool.requestLoan{value: collateral}(
            loanAmount,
            creditScore,
            pA,
            pB,
            pC,
            pubSignals
        );
        
        // Verify loan was created
        ZKreditLendingPool.LoanRequest memory loan = lendingPool.getLoan(borrower);
        assertEq(loan.borrower, borrower);
        assertEq(loan.amount, loanAmount);
        assertEq(loan.collateral, collateral);
        assertEq(loan.creditScore, creditScore);
        assertTrue(loan.approved);
    }
    
    function testAntiReplayProtection() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        uint256 loanAmount = 1 ether;
        uint256 collateral = 1.5 ether;
        
        // First request succeeds
        vm.prank(borrower);
        lendingPool.requestLoan{value: collateral}(
            loanAmount,
            75,
            pA,
            pB,
            pC,
            pubSignals
        );
        
        // Repay loan first
        vm.prank(borrower);
        lendingPool.repayLoan{value: loanAmount}();
        
        // Second request with same proof should fail (anti-replay)
        vm.deal(borrower, 10 ether); // Refund borrower
        vm.prank(borrower);
        vm.expectRevert("ZKreditLendingPool: proof already used");
        lendingPool.requestLoan{value: collateral}(
            loanAmount,
            75,
            pA,
            pB,
            pC,
            pubSignals
        );
    }
    
    function testInvalidProofRejection() public {
        // Set mock verifier to reject proofs
        mockVerifier.setShouldPass(false);
        
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        vm.prank(borrower);
        vm.expectRevert("ZKreditLendingPool: invalid ZK proof");
        lendingPool.requestLoan{value: 2 ether}(
            1 ether,
            80,
            pA,
            pB,
            pC,
            pubSignals
        );
    }
    
    function testModelHashMismatchRejection() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(keccak256("wrong_model")); // Wrong model hash
        
        vm.prank(borrower);
        vm.expectRevert("ZKreditLendingPool: model hash mismatch");
        lendingPool.requestLoan{value: 2 ether}(
            1 ether,
            80,
            pA,
            pB,
            pC,
            pubSignals
        );
    }
    
    function testConstraintFailureRejection() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 1000 * 1e18; // Income too low
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        vm.prank(borrower);
        vm.expectRevert("ZKreditLendingPool: fails constraint checks");
        lendingPool.requestLoan{value: 2 ether}(
            1 ether,
            80,
            pA,
            pB,
            pC,
            pubSignals
        );
    }
    
    function testInsufficientCollateralRejection() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        vm.prank(borrower);
        vm.expectRevert("ZKreditLendingPool: insufficient collateral");
        lendingPool.requestLoan{value: 0.5 ether}( // Not enough collateral
            1 ether,
            80,
            pA,
            pB,
            pC,
            pubSignals
        );
    }
    
    function testLoanRepayment() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        uint256 loanAmount = 1 ether;
        uint256 collateral = 1.2 ether;
        
        vm.prank(borrower);
        lendingPool.requestLoan{value: collateral}(
            loanAmount,
            85,
            pA,
            pB,
            pC,
            pubSignals
        );
        
        uint256 balanceBefore = borrower.balance;
        
        vm.prank(borrower);
        lendingPool.repayLoan{value: loanAmount}();
        
        // Borrower should have received collateral back
        assertEq(borrower.balance, balanceBefore - loanAmount + collateral);
        
        // Loan should be cleared
        ZKreditLendingPool.LoanRequest memory loan = lendingPool.getLoan(borrower);
        assertEq(loan.amount, 0);
    }
    
    function testLiquidation() public {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = 10000 * 1e18;
        pubSignals[1] = 2000;
        pubSignals[2] = uint256(DEMO_MODEL_HASH);
        
        uint256 loanAmount = 1 ether;
        uint256 collateral = 1.2 ether;
        
        vm.prank(borrower);
        lendingPool.requestLoan{value: collateral}(
            loanAmount,
            85,
            pA,
            pB,
            pC,
            pubSignals
        );
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 31 days);
        
        uint256 poolLiquidityBefore = lendingPool.poolLiquidity();
        
        // Anyone can liquidate
        lendingPool.liquidate(borrower);
        
        // Pool should receive collateral
        assertEq(lendingPool.poolLiquidity(), poolLiquidityBefore + collateral);
        
        // Loan should be cleared
        ZKreditLendingPool.LoanRequest memory loan = lendingPool.getLoan(borrower);
        assertEq(loan.amount, 0);
    }
}
