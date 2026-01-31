# ZKredit Frontend Integration Guide

## 1. Introduction

This guide provides a comprehensive overview for building a frontend application that interacts with the ZKredit decentralized lending protocol. The frontend's primary role is to provide a user-friendly interface for two main actors: **Liquidity Providers** and **Borrowers**.

A key challenge and feature of this application is the **client-side zero-knowledge proof generation**, which allows users to apply for loans based on a private credit score without revealing their underlying financial data.

## 2. Core User Flows

### Flow 1: Liquidity Provider (LP)

This is the simplest flow. LPs are users who want to supply capital to the lending pool to earn yield.

1.  **Connect Wallet:** The user connects their Ethereum wallet (e.g., MetaMask).
2.  **Display Pool Stats:** The UI should show key pool metrics like Total Value Locked (TVL) and available liquidity by reading from the `ZKreditLendingPool` contract's public variables (`totalValueLocked`, `poolLiquidity`).
3.  **Deposit Liquidity:**
    -   The user enters an amount of ETH to deposit.
    -   The frontend calls the `depositLiquidity()` function on the `ZKreditLendingPool` contract, sending the specified amount of ETH.
    -   The UI updates to reflect the new pool stats and listens for the `LiquidityDeposited` event to confirm the transaction.

### Flow 2: Borrower

This is the more complex flow, involving off-chain data fetching, client-side cryptography, and multiple smart contract interactions.

![Borrower Flow Diagram](https://i.imgur.com/example.png)  <!-- Placeholder for a real diagram -->

#### **Step-by-Step Borrower Walkthrough:**

**Step 1: Connect Wallet**
-   Same as the LP flow. Use standard libraries like `wagmi` and `RainbowKit` for a smooth experience.

**Step 2: Select User Profile (For Demo)**
-   To demonstrate the system, the frontend should fetch the list of mock users from the **Mock Oracle** at `GET /api/users`.
-   The user selects a profile (e.g., Alice, Bob) to simulate different financial scenarios.

**Step 3: Fetch Attested Financial Data**
-   Once a user is selected, the frontend makes a request to the **Mock Oracle** at `GET /api/financial-data?userId=<ID>`.
-   The response will contain the user's mock financial data (`income`, `debt`, `creditScore`) and, crucially, a `signature`. The frontend must store all of this data securely.

**Step 4: Deposit Security Bond**
-   Before requesting a loan, the user must deposit a security bond to discourage spam and malicious proofs.
-   The frontend calls the `depositSecurity()` function on `ZKreditLendingPool`, sending the `SECURITY_DEPOSIT` amount (e.g., 0.01 ETH).
-   Listen for the `SecurityDepositMade` event to confirm.

**Step 5: Generate ZK Proof (Client-Side)**
-   This is the most technically challenging step. The frontend orchestrates the `ezkl` prover, which runs locally on the user's machine.
-   **Prerequisites:** The client application must have access to:
    1.  The `ezkl` binary (or a WASM-compiled version).
    2.  The ML model file: `circuits/model.onnx`.
    3.  The proving key: `circuits/pk.key`.
    4.  The SRS file (trusted setup): `circuits/kzg.srs`.
-   **Process:**
    1.  **Create Witness:** The frontend creates a `witness.json` file. The `input_data` field of this JSON should be populated with the financial data fetched in Step 3, scaled correctly as per the model's requirements.
    2.  **Execute Prover:** The frontend spawns a child process to execute the `ezkl prove` command.
        ```bash
        ezkl prove --witness witness.json --model model.onnx --pk-path pk.key --proof-path proof.json --srs-path kzg.srs
        ```
    3.  **Parse Output:** The frontend reads the resulting `proof.json`. This file contains the proof components (`_pA`, `_pB`, `_pC`) and the public signals/outputs (`_pubSignals`) needed for the smart contract call.

**Step 6: Request the Loan**
-   The user specifies the desired loan `amount` and the collateral they will provide (sent as `msg.value`).
-   The frontend calls the `requestLoan()` function on `ZKreditLendingPool`, passing all the required parameters extracted from the `proof.json` in the previous step.
-   The collateral amount must also be sent with the transaction (`value` field). This value must meet the on-chain requirement calculated from the `ConstraintRegistry`.

**Step 7: Display Loan Status**
-   The frontend must listen for `LoanApproved` and `LoanRejected` events to give the user real-time feedback on their application.
-   If the loan is approved, the UI should display the loan details (amount, collateral, repayment deadline) by calling the `getLoan(userAddress)` view function.

**Step 8: Repay the Loan**
-   To repay, the user's frontend calls the `repayLoan()` function, sending the original loan amount as `msg.value`.
-   If successful, the contract will return the user's original collateral. The frontend should listen for the `LoanRepaid` event to confirm.

## 3. Smart Contract Interaction Cheatsheet

| Function Name         | When to Call                               | Parameters                                                                   | `msg.value`           | Key Event to Watch          |
| --------------------- | ------------------------------------------ | ---------------------------------------------------------------------------- | --------------------- | --------------------------- |
| `depositLiquidity()`  | When an LP adds funds to the pool.         | -                                                                            | `depositAmount`       | `LiquidityDeposited`        |
| `depositSecurity()`   | **Before** a borrower requests a loan.     | -                                                                            | `SECURITY_DEPOSIT`    | `SecurityDepositMade`       |
| `requestLoan()`       | When a borrower applies for a loan.        | `_amount`, `_creditScore`, `_pA`, `_pB`, `_pC`, `_pubSignals`                | `collateralAmount`    | `LoanApproved`, `LoanRejected`, `AttackPrevented` |
| `repayLoan()`         | When a borrower repays their active loan.  | -                                                                            | `repaymentAmount`     | `LoanRepaid`                |
| `getLoan(address)`    | To display details of a user's active loan.| `_borrower`                                                                  | -                     | -                           |
| `poolLiquidity()`     | To display total available liquidity.      | -                                                                            | -                     | -                           |
| `totalValueLocked()`  | To display the contract's TVL.             | -                                                                            | -                     | -                           |


## 4. "Security Lab" Feature

A powerful feature of the ZKredit frontend would be a "Security Lab" designed to demonstrate the effectiveness of the 5-layer verification system.

-   **Goal:** Allow users to intentionally craft "malicious" loan requests and see exactly which layer of the contract's defense catches the attack.
-   **Implementation:**
    1.  Provide UI controls that allow a user to tamper with the loan request process (e.g., a "Use Stale Proof" button, a "Forge Input Data" toggle, a "Use Wrong Model" selector).
    2.  When a tampered request is sent, the transaction will revert.
    3.  The frontend should listen for the `AttackPrevented` event. This event is specifically designed for this purpose and contains:
        -   `attacker`: The user's address.
        -   `attackType`: A string like "REPLAY" or "MODEL_TAMPER".
        -   `lesson`: A human-readable explanation of why the attack failed.
        -   `layer`: The verification layer number that caught the attack.
    4.  The UI can then display a clear, educational message: *"Attack Prevented! Your attempt to use a stale proof was caught by **Layer 0: Anti-Replay Prevention**. Lesson: Proofs are one-time use."* This turns a failed transaction into a powerful learning experience.
