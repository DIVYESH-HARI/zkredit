#!/usr/bin/env python3
"""
ZKredit Credit Model Training Script

Trains a minimal credit risk neural network and exports to ONNX format
for zero-knowledge proof circuit generation with EZKL.

Architecture: 10 features -> 16 -> 8 -> 1 (credit score 0-100)
"""

import sys
import os

# Add onnx package path (installed to C:\onnx to avoid Windows path issues)
sys.path.insert(0, r'C:\onnx')

import torch
import torch.nn as nn
import numpy as np
import hashlib
from pathlib import Path


class CreditModel(nn.Module):
    """
    Minimal credit scoring neural network.
    
    Architecture designed for efficient ZK proof generation:
    - 3 layers with ReLU activations
    - Final sigmoid scaled to 0-100 range
    - Small parameter count for fast proving
    """
    
    def __init__(self):
        super().__init__()
        self.layer1 = nn.Linear(10, 16)  # 10 features -> 16 neurons
        self.layer2 = nn.Linear(16, 8)   # 16 -> 8 neurons
        self.layer3 = nn.Linear(8, 1)    # 8 -> 1 (credit score)
        self.relu = nn.ReLU()
        self.sigmoid = nn.Sigmoid()
        
    def forward(self, x):
        x = self.relu(self.layer1(x))
        x = self.relu(self.layer2(x))
        x = self.sigmoid(self.layer3(x))
        return x * 100  # Scale to 0-100 credit score range


def generate_synthetic_data(n_samples: int = 1000) -> tuple:
    """
    Generate synthetic credit data for training.
    
    Features (normalized):
    0: income (annual, normalized)
    1: debt (total, normalized)
    2: debt_to_income ratio
    3: employment_years
    4: age (normalized)
    5: num_credit_accounts
    6: credit_utilization
    7: payment_history_score
    8: num_late_payments
    9: months_since_delinquency
    
    Returns: (X, y) where y is credit score 0-100
    """
    np.random.seed(42)
    
    # Generate features
    X = np.random.randn(n_samples, 10).astype(np.float32)
    
    # Create target based on weighted combination of features
    # Positive factors: income, employment, payment history
    # Negative factors: debt, late payments, utilization
    score = (
        X[:, 0] * 0.25 +   # income (positive)
        X[:, 1] * -0.20 +  # debt (negative)
        X[:, 2] * -0.15 +  # DTI (negative)
        X[:, 3] * 0.10 +   # employment years (positive)
        X[:, 4] * 0.05 +   # age (slight positive)
        X[:, 5] * 0.10 +   # credit accounts (positive)
        X[:, 6] * -0.10 +  # utilization (negative)
        X[:, 7] * 0.20 +   # payment history (positive)
        X[:, 8] * -0.15 +  # late payments (negative)
        X[:, 9] * 0.05     # months since delinquency (positive)
    )
    
    # Normalize to 0-100 range
    y = ((score - score.min()) / (score.max() - score.min()) * 100).astype(np.float32)
    
    return X, y


def train_model(epochs: int = 50, lr: float = 0.01) -> CreditModel:
    """
    Train the credit model on synthetic data.
    
    Args:
        epochs: Number of training epochs
        lr: Learning rate
        
    Returns: Trained CreditModel
    """
    print("=" * 50)
    print("ZKredit Credit Model Training")
    print("=" * 50)
    
    # Generate data
    print("\n[1/4] Generating synthetic training data...")
    X, y = generate_synthetic_data(1000)
    X_train = torch.FloatTensor(X)
    y_train = torch.FloatTensor(y).reshape(-1, 1)
    print(f"      Generated {len(X)} samples with {X.shape[1]} features")
    
    # Initialize model
    print("\n[2/4] Initializing model...")
    model = CreditModel()
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    
    param_count = sum(p.numel() for p in model.parameters())
    print(f"      Model architecture: 10 -> 16 -> 8 -> 1")
    print(f"      Total parameters: {param_count}")
    
    # Training loop
    print(f"\n[3/4] Training for {epochs} epochs...")
    for epoch in range(epochs):
        optimizer.zero_grad()
        outputs = model(X_train)
        loss = criterion(outputs, y_train)
        loss.backward()
        optimizer.step()
        
        if (epoch + 1) % 10 == 0:
            print(f"      Epoch {epoch + 1:3d}/{epochs} | Loss: {loss.item():.4f}")
    
    print(f"\n      Final Loss: {loss.item():.4f}")
    
    # Evaluate
    model.eval()
    with torch.no_grad():
        predictions = model(X_train)
        mae = torch.mean(torch.abs(predictions - y_train)).item()
        print(f"      Mean Absolute Error: {mae:.2f} points")
    
    return model


def export_to_onnx(model: CreditModel, output_dir: Path) -> str:
    """
    Export trained model to ONNX format.
    
    Args:
        model: Trained CreditModel
        output_dir: Directory to save ONNX file
        
    Returns: Path to saved ONNX file
    """
    print("\n[4/4] Exporting to ONNX...")
    
    output_dir.mkdir(parents=True, exist_ok=True)
    onnx_path = output_dir / "model.onnx"
    
    # Create dummy input
    dummy_input = torch.randn(1, 10)
    
    # Export to ONNX
    model.eval()
    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_path),
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        },
        opset_version=10,
        do_constant_folding=True
    )
    
    print(f"      Saved model to: {onnx_path}")
    
    # Calculate and save hash
    with open(onnx_path, "rb") as f:
        model_hash = hashlib.sha256(f.read()).hexdigest()
    
    hash_path = output_dir / "model_hash.txt"
    with open(hash_path, "w") as f:
        f.write(model_hash)
    
    print(f"      Model SHA256: {model_hash[:16]}...{model_hash[-16:]}")
    print(f"      Hash saved to: {hash_path}")
    
    # Verify ONNX model
    import onnx
    onnx_model = onnx.load(str(onnx_path))
    onnx.checker.check_model(onnx_model)
    print("      ONNX model verification: PASSED ✓")
    
    return str(onnx_path)


def main():
    """Main entry point."""
    # Determine output directory
    script_dir = Path(__file__).parent.parent
    circuits_dir = script_dir / "circuits"
    
    # Train model
    model = train_model(epochs=50, lr=0.01)
    
    # Export to ONNX
    onnx_path = export_to_onnx(model, circuits_dir)
    
    print("\n" + "=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"\nNext steps:")
    print(f"  1. cd circuits")
    print(f"  2. Run generate_circuit.ps1 to create ZK circuit")
    print(f"  3. Commit model hash to ModelRegistry contract")
    
    return onnx_path


if __name__ == "__main__":
    main()
