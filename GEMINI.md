# GEMINI.md: ZKredit Project

This document provides a comprehensive overview of the ZKredit project, its architecture, and instructions for development and testing.

## Project Overview

ZKredit is a decentralized finance (DeFi) project that enables privacy-preserving credit scoring. It allows borrowers to prove their creditworthiness using zero-knowledge (ZK) proofs without revealing their actual financial data. This allows the protocol to offer better loan terms (e.g., lower collateral) to users with good credit.

The project is a monorepo containing:
-   **Smart Contracts (`contracts/`):** Written in Solidity using the Foundry framework. The core logic resides in `ZKreditLendingPool.sol`, which implements a 5-layer verification process for security.
-   **ZK Circuits (`circuits/`):** Uses `ezkl` to create ZK proofs from ONNX models. The machine learning models are trained in Python.
-   **Frontend (`client/`):** A React/Vite application that provides the user interface for loan applications and demos.
-   **Mock Oracle (`mock-oracle/`):** A Node.js Express server that simulates a bank oracle, providing signed financial data for demo purposes.
-   **Scripts (`scripts/`):** Contains various scripts for tasks like end-to-end testing (`test_e2e.py`), model training (`train_model.py`), and demo recording.

### Key Technologies

-   **Blockchain:** Solidity, Foundry, Base Sepolia (L2)
-   **Zero-Knowledge:** ezkl, Halo2, ONNX
-   **Frontend:** React, Vite, RainbowKit, ethers.js
-   **Backend/Tooling:** Node.js, Express, Python

## Building and Running

### Prerequisites

-   [Node.js v18+](https://nodejs.org/)
-   [Python 3.10+](https://www.python.org/)
-   [Rust](https://www.rust-lang.org/tools/install) (Required for Foundry and ezkl)

### Installation

1.  **Run the setup script:** This will attempt to install necessary tools like Foundry.
    ```powershell
    ./setup.ps1
    ```

2.  **Install Node.js dependencies:**
    ```bash
    npm install
    ```

### Running the Application

1.  **Start the Frontend Client:**
    ```bash
    npm run dev:client
    ```
    The client will be available at `http://localhost:5173`.

2.  **Start the Mock Bank Oracle:**
    ```bash
    npm run dev:oracle
    ```
    The oracle will run on `http://localhost:3001`.

## Testing

### Smart Contract Tests

The project uses Foundry for smart contract testing.

```bash
cd contracts
forge test
```

### End-to-End Tests

The `scripts/test_e2e.py` script runs a full end-to-end test suite that simulates user interactions and attack scenarios.

```bash
python scripts/test_e2e.py
```

## Development Conventions

-   The project is structured as a monorepo using `npm` workspaces for the `client` and `mock-oracle`.
-   Smart contracts are developed and tested using the Foundry framework. Key contracts are located in `contracts/src`.
-   The `ZKreditLendingPool.sol` contract is the centerpiece, implementing a "Constraint Sandwich" 5-layer verification model for robust security.
-   The system is designed for transparency. Demos and attack scenarios are documented in `DEMO_SCRIPT.md` and can be tested interactively via the frontend's "Security Lab".
-   The ZK machine learning models are trained using Python/PyTorch, exported to ONNX, and then converted into ZK circuits using `ezkl`.
-   The mock oracle simulates bank data attestation using ECDSA signatures for the demo, with a plan to use TLSNotary in production for true cryptographic proof of data origin.
