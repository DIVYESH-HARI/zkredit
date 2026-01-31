# ZKredit Machine Learning Model Documentation

## Overview

The machine learning model is a core component of the ZKredit protocol, responsible for generating a credit score based on a user's financial data. To maintain privacy, this model is executed within a zero-knowledge proof (ZKP) environment. This means a user can prove they ran the model correctly and obtained a certain credit score without revealing their sensitive financial inputs (income, debt, etc.).

The entire ML pipeline is designed for compatibility with ZK-SNARKs, prioritizing simplicity and efficiency.

## Technology Stack

-   **Language:** Python
-   **Frameworks:**
    -   PyTorch: For defining and training the neural network.
    -   ONNX (Open Neural Network Exchange): As the intermediary format for exporting the trained model. `ezkl`, the ZK proving toolkit used in this project, consumes ONNX models.

## Model Pipeline

### 1. Training

-   **Script:** `scripts/train_model.py`
-   **Process:**
    1.  **Data:** The script uses a sample dataset of financial profiles (income, debt, existing credit score) and corresponding loan default statuses.
    2.  **Architecture:** A simple `CreditModel` neural network is defined using PyTorch. The architecture is kept minimal (a few linear layers with ReLU activations) to ensure it can be efficiently translated into a ZK circuit.
    3.  **Training:** The model is trained on the dataset to learn the relationship between a user's financial inputs and their likelihood of defaulting on a loan.
    4.  **Output:** The model outputs a single numerical value representing the user's "creditworthiness score."

### 2. Export to ONNX

-   **Script:** `scripts/train_model.py`
-   **Process:**
    1.  After training, the script uses PyTorch's built-in functionality to export the `CreditModel` into the ONNX format.
    2.  The output file is saved as `circuits/model.onnx`. This file contains a standardized, interoperable representation of the model's architecture and learned weights.

### 3. Model Hashing

-   **Script:** `scripts/train_model.py`
-   **Process:**
    1.  To ensure that only the officially approved model is used for on-chain credit scoring, the script calculates a SHA-256 hash of the exported `model.onnx` data.
    2.  This hash is written to `circuits/model_hash.txt`.
-   **On-Chain Verification:** The `ModelRegistry.sol` smart contract stores this official model hash. When a user submits a loan application, the ZK proof implicitly includes a commitment to the model they used. The `ZKreditLendingPool` contract verifies that the hash of the model used in the proof matches the one stored in the registry, preventing users from submitting proofs generated with their own (potentially malicious) models.

## Model Details

-   **Input Features:** The model expects the following inputs, which are the same data points provided by the mock oracle:
    1.  `income`
    2.  `debt`
    3.  `creditScore`
-   **Output:** A single floating-point number representing the ZKredit score. This score is a public output of the ZK circuit, meaning it is visible on-chain and can be used by the `ZKreditLendingPool` contract to determine loan terms.
