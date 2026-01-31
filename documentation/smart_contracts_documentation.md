# ZKredit Smart Contract Documentation

## Overview

The ZKredit smart contract system is designed as a modular, secure, and transparent lending pool that leverages zero-knowledge proofs for private credit scoring. The architecture is centered around the `ZKreditLendingPool.sol` contract, which acts as the main user entry point and orchestrator.

The system's security is built on a "Constraint Sandwich" model, a 5-layer verification process that combines on-chain rules with cryptographic proofs to create a robust defense-in-depth environment. This architecture is supported by a trio of registry contracts that manage model versions, lending constraints, and security events.

## Core Architecture Diagram

```
+---------------------------+
|   User (Borrower/LP)      |
+-------------+-------------+
              |
              v
+-------------+-------------+      +-------------------------+
| ZKreditLendingPool.sol    |<---->|  ConstraintRegistry.sol |
| (Main Contract)           |      |  (The Iron Rules)       |
|                           |      +-------------------------+
| - requestLoan()           |
| - repayLoan()             |      +-------------------------+
| - depositLiquidity()      |<---->|  ModelRegistry.sol      |
| - 5-Layer Verification    |      |  (The Glass Box)        |
+-------------+-------------+      +-------------------------+
              |
              | (verifyProof)      +-------------------------+
              v                    |  SecurityRegistry.sol   |
+-------------+-------------+      |  (The Watchdog)         |
|     Verifier.sol          |<---->|                         |
| (EZKL Auto-generated)     |      +-------------------------+
+---------------------------+
```

---

## Core Contract: `ZKreditLendingPool.sol`

This is the central contract that manages all lending and verification logic.

### The 5-Layer "Constraint Sandwich" Verification

The `requestLoan` function implements a multi-layered verification process designed to be highly secure and educational, where each layer provides a specific guarantee:

-   **Layer 0: Anti-Replay Prevention:**
    -   **Mechanism:** Hashes the incoming proof and its public signals. Stores the hash to ensure it can only be used once.
    -   **Purpose:** Prevents a simple "replay attack" where an attacker tries to reuse a valid, old proof.

-   **Layer 1: Upper Bound - Hard Constraints:**
    -   **Mechanism:** Checks the public inputs of the proof (e.g., income, DTI) against hard-coded rules stored in the `ConstraintRegistry.sol`.
    -   **Purpose:** Enforces fundamental business logic and risk parameters (e.g., `DTI < 30%`) that must hold true regardless of the ZK proof's validity.

-   **Layer 2: Data Provenance (Bank Signature):**
    -   **Mechanism:** (Simplified in the current implementation). In a production scenario, this layer would verify an ECDSA signature from a trusted oracle (the "bank") to prove the authenticity of the financial data used.
    -   **Purpose:** Ensures the data fed into the ZK proof comes from a legitimate source, preventing a "Garbage-In, Garbage-Out" (GIGO) attack.

-   **Layer 3: Model Execution (ZK Proof Verification):**
    -   **Mechanism:** Calls the `verifyProof` function on the `Verifier.sol` contract, passing the ZK proof and public signals.
    -   **Purpose:** This is the core privacy-preserving step. It cryptographically verifies that the user correctly executed the credit scoring model without revealing their private financial inputs.

-   **Layer 4: Lower Bound - Output Validation:**
    -   **Mechanism:** Checks the public outputs from the ZK proof (the final credit score) to ensure they fall within a valid range (e.g., 0-100).
    -   **Purpose:** Acts as a sanity check and final backstop against unforeseen issues or manipulations within the ZK circuit that might produce nonsensical results.

-   **Layer 5: Model Hash Consistency:**
    -   **Mechanism:** Compares the ML model hash included in the ZK proof's public signals against the official hash stored in `ModelRegistry.sol`.
    -   **Purpose:** Prevents a sophisticated "model tampering" attack where a user generates a valid proof using a modified, easier-to-pass ML model.

### Key Functions

-   `requestLoan(...)`: The main function for borrowers. It accepts the loan amount, the ZK proof, and public signals, and runs the 5-layer verification.
-   `repayLoan()`: Allows a borrower to repay their outstanding loan and reclaim their collateral.
-   `depositLiquidity()`: Allows liquidity providers (LPs) to deposit funds into the pool to earn yield.
-   `depositSecurity()`: A prerequisite for borrowing, where a user deposits a small amount of ETH as a security deposit, which can be slashed if they submit a malicious or invalid proof request.

---

## Registry Contracts

### `ConstraintRegistry.sol` (The Iron Rules)

-   **Purpose:** Stores and enforces the fundamental, non-negotiable rules of the lending pool.
-   **Key Data:**
    -   Minimum income (`minIncome`)
    -   Maximum Debt-to-Income ratio (`maxDTI`)
    -   Minimum credit score (`minCreditScore`)
    -   Collateral ratios for different credit score tiers.
-   **Interaction:** The `ZKreditLendingPool` reads from this contract during **Layer 1** of its verification process.

### `ModelRegistry.sol` (The Glass Box)

-   **Purpose:** Acts as the source of truth for the official, approved machine learning model.
-   **Key Data:**
    -   `currentModelHash`: The SHA-256 hash of the officially deployed `model.onnx` file.
    -   `modelVersion`: A versioning system to track model updates.
-   **Interaction:** The `ZKreditLendingPool` reads from this contract during **Layer 5** of its verification process to ensure proof-model consistency.

### `SecurityRegistry.sol` (The Watchdog)

-   **Purpose:** An event-logging and monitoring contract that tracks malicious activity.
-   **Key Data:**
    -   Records of failed loan applications categorized by attack type (e.g., `GIGO`, `REPLAY_ATTACK`).
    -   A history of slashing events.
    -   A simple blacklisting system for repeated offenders.
-   **Interaction:** The `ZKreditLendingPool` writes to this contract whenever a verification layer fails, providing a transparent, on-chain audit trail of thwarted attacks.

---

## Verifier Contract

### `Verifier.sol`

-   **Purpose:** This contract contains the low-level cryptographic logic required to verify Halo2 ZK-SNARKs on the EVM.
-   **Generation:** It is **auto-generated** by the `ezkl` toolkit during the one-time trusted setup phase (`ezkl create-evm-verifier`). It is not meant to be edited manually.
-   **Interaction:** The `ZKreditLendingPool` calls the `verifyProof` function in this contract during **Layer 3** of its verification process. It is the on-chain representation of the `vk.key` (Verification Key).
