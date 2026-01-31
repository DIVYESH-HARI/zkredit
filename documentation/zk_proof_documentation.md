# ZKredit Zero-Knowledge Proof Documentation

## Overview

Zero-Knowledge Proofs (ZKPs) are the cryptographic foundation of the ZKredit protocol, enabling privacy-preserving credit scoring. Using ZKPs, a borrower can prove to the lending pool contract that they have correctly executed the official credit scoring model on their private financial data and achieved a certain score, all without revealing the sensitive inputs (e.g., their income or debt).

This project uses `ezkl`, a powerful library and command-line tool designed to create ZK-SNARKs from common machine learning formats like ONNX.

## Technology Stack

-   **ZK Toolkit:** `ezkl`
-   **Proving System:** Halo2 (with KZG commitments)

## The ZK Pipeline

The process can be broken down into two main phases: a one-time trusted setup phase and a per-user proof generation phase.

### 1. Trusted Setup (Developer Task)

This is a one-time process performed by the developers to create the necessary cryptographic components for the ZK scheme.

-   **Script:** `circuits/generate_circuit.ps1`
-   **Purpose:** This script orchestrates the `ezkl` CLI to build all the required assets from the `model.onnx` file.
-   **Key Steps:**
    1.  **`ezkl get-srs`**: Downloads the trusted setup parameters (also known as the "toxic waste"). This is a large file containing common cryptographic primitives required for the KZG commitment scheme.
    2.  **`ezkl compile-circuit`**: Takes the `model.onnx` file and compiles it into a ZK circuit representation. This step defines the constraints that the prover must satisfy.
    3.  **`ezkl setup`**: Using the compiled circuit and trusted setup, this step generates two critical files:
        -   `pk.key` (Proving Key): This key is required to **generate** a proof. It is made public and distributed to all users (clients) who wish to apply for a loan.
        -   `vk.key` (Verification Key): This key is used to **verify** a proof. It is much smaller than the proving key and is used by the on-chain verifier.
    4.  **`ezkl create-evm-verifier`**: This command takes the `vk.key` and auto-generates a Solidity smart contract, `contracts/src/Verifier.sol`. This contract contains the logic to verify proofs on the Ethereum Virtual Machine (EVM).

### 2. Proof Generation (User/Client Task)

This process is performed by any user who wants to apply for a loan. It is executed entirely on the client-side to ensure the user's private data never leaves their machine.

-   **Command:** `ezkl prove`
-   **Process:**
    1.  **Get Attested Data:** The user first fetches their signed financial data from the mock oracle.
    2.  **Generate Witness:** The user's financial data (income, debt, credit score) is formatted into a specific JSON file called a "witness" (e.g., `input.json`). This witness represents the private inputs to the ZK circuit.
    3.  **Run Prover:** The user's machine executes the `ezkl prove` command, which takes the witness, the public `pk.key`, and the `model.onnx` file as input.
    4.  **Output:** The command produces a `proof.json` file. This file contains the cryptographic proof and the public outputs of the computation (i.e., the calculated creditworthiness score).

**Example `ezkl prove` command:**

```bash
ezkl prove --witness <path_to_witness.json> --model <path_to_model.onnx> --pk-path <path_to_pk.key> --proof-path <path_to_proof.json> --srs-path <path_to_kzg.srs>
```

### 3. On-Chain Verification

-   **Contract:** `contracts/src/Verifier.sol`
-   **Process:**
    1.  The user submits the generated `proof.json` and the public outputs to the `ZKreditLendingPool.sol` contract when calling the `applyForLoan` function.
    2.  The `ZKreditLendingPool` contract forwards the proof to the `Verifier.sol` contract.
    3.  The `verify` function in `Verifier.sol` performs the cryptographic checks. If the proof is valid, the function returns `true`, confirming to the lending pool that the user's credit score was calculated correctly and honestly.
