# 🔐 ZKredit

**Privacy-Preserving DeFi Lending with Zero-Knowledge Machine Learning**

ZKredit enables borrowers to prove their creditworthiness using Zero-Knowledge proofs without revealing sensitive financial data. This allows the protocol to offer better loan terms (lower collateral) to users with good credit while maintaining complete privacy.

---

## 🎯 The Problem

Traditional DeFi lending suffers from:
- **Over-Collateralization**: 150%+ collateral required because lenders can't assess creditworthiness
- **Privacy Risks**: Revealing financial data on public blockchains is unacceptable
- **Oracle Trust**: Centralized oracles can be manipulated or compromised

## 💡 Our Solution

ZKredit solves this with a **"Constraint Sandwich"** architecture:
- **Client-Side ML**: Credit scoring runs entirely in your browser—data never leaves your device
- **Zero-Knowledge Proofs**: Prove your score is valid without revealing the underlying data
- **5-Layer Verification**: Multiple security layers catch attacks that any single check would miss
- **zkTLS (PoC)**: Cryptographic proof that data came from a real bank HTTPS session

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔒 **Privacy-First** | Financial data never leaves your browser |
| 🧠 **ZKML Scoring** | ML model runs client-side, verified via ZK proof |
| 🛡️ **5-Layer Security** | Anti-replay, constraints, provenance, ZK, model hash |
| 🏦 **Bank Attestation** | ECDSA-signed data with zkTLS proof-of-concept |
| ⚔️ **Attack Demos** | See how Eve (model tampering) and Mallory (data tampering) get caught |
| 📊 **Visual Verification** | Watch each security layer verify in real-time |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER'S BROWSER                            │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │  React   │──▶│   ONNX   │──▶│   EZKL   │──▶│   Tx     │     │
│  │    UI    │   │  Model   │   │  Prover  │   │ Builder  │     │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘     │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐
│   Bank API   │    │  zkTLS PoC   │    │   Base Sepolia L2    │
│  (Mock Oracle)│    │ (TLSNotary) │    │  ZKreditLendingPool  │
│   ECDSA Sign │    │  Session Proof│    │  5-Layer Verifier   │
└──────────────┘    └──────────────┘    └──────────────────────┘
```

---

## 🔄 User Flow

1. **Select Profile** → Choose Alice (good credit), Bob (poor), or attack users (Eve/Mallory)
2. **Fetch Bank Data** → API returns signed financial data (Income, Debt, Score)
3. **zkTLS Verification** → Prove data came from real HTTPS session (PoC)
4. **ML Scoring** → ONNX model runs locally, calculates credit score
5. **ZK Proof** → Generate proof that score was computed correctly
6. **On-Chain Verification** → Smart contract runs 5-layer security check
7. **Settlement** → Loan approved with reduced collateral (or attack blocked!)

---

## 🛡️ 5-Layer "Constraint Sandwich"

| Layer | Name | What It Catches |
|-------|------|-----------------|
| 0 | Anti-Replay | Reused proofs |
| 1 | Hard Constraints | Income < $30k, DTI > 30% |
| 2 | Data Provenance | Tampered bank data (Mallory!) |
| 3 | ZK Verification | Invalid proof computation |
| 4 | Output Bounds | Score > 100 or < 0 |
| 5 | Model Hash | Modified ML model (Eve!) |

---

## 🚀 Quick Start

### Prerequisites

- [Node.js v18+](https://nodejs.org/)
- [Python 3.10+](https://www.python.org/)
- [Rust](https://www.rust-lang.org/tools/install) (for EZKL & Foundry)

### Installation

```powershell
# 1. Clone the repository
git clone https://github.com/DIVYESH-HARI/zkredit.git
cd zkredit

# 2. Run setup script (Windows)
./setup.ps1

# 3. Install Node dependencies
npm install

# 4. Install Rust tools (if not already installed)
cargo install ezkl
cargo install --git https://github.com/foundry-rs/foundry --profile local --force foundry-cli anvil chisel
```

### Running the Application

```powershell
# Terminal 1: Start the Mock Bank Oracle
npm run dev:oracle

# Terminal 2: Start the Frontend Client
npm run dev:client
```

Open **http://localhost:5173** in your browser.

---

## 📁 Project Structure

```
zkredit/
├── client/                 # React/Vite Frontend
│   └── src/
│       ├── App.jsx        # Main application with 5-step flow
│       └── index.css      # Glassmorphism design system
│
├── contracts/              # Solidity Smart Contracts (Foundry)
│   └── src/
│       ├── ZKreditLendingPool.sol  # Core lending logic
│       ├── Verifier.sol            # Halo2 proof verifier
│       ├── ConstraintRegistry.sol  # Risk parameters
│       ├── ModelRegistry.sol       # ML model hash registry
│       └── SecurityRegistry.sol    # Attack logging
│
├── circuits/               # ZK Circuit Files (EZKL)
│   ├── model.onnx         # Credit scoring ML model
│   ├── pk.key             # Proving key
│   ├── vk.key             # Verification key
│   └── settings.json      # Circuit configuration
│
├── mock-oracle/            # Node.js Bank API Simulator
│   └── server.js          # Express server with ECDSA signing
│
├── scripts/                # Utility Scripts
│   ├── train_model.py     # PyTorch model training
│   └── test_e2e.py        # End-to-end testing
│
└── documentation/          # Technical Docs
    ├── architecture_new.md # System diagrams
    └── *.md               # Component documentation
```

---

## 🧪 Testing

### Smart Contract Tests
```bash
cd contracts
forge test
```

### End-to-End Tests
```bash
python scripts/test_e2e.py
```

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | React 18, Vite, Vanilla CSS |
| **Smart Contracts** | Solidity 0.8.19, Foundry |
| **ZK Proofs** | EZKL, Halo2, KZG |
| **ML Model** | PyTorch, ONNX |
| **Mock Oracle** | Node.js, Express, ECDSA |
| **Blockchain** | Base Sepolia (L2) |

---

## 📖 Documentation

- [Architecture Diagrams](./documentation/architecture_new.md)
- [Smart Contract Docs](./documentation/smart_contracts_documentation.md)
- [Frontend Integration](./documentation/frontend_integration_guide.md)
- [ML Model Docs](./documentation/ml_model_documentation.md)
- [ZK Proof System](./documentation/zk_proof_documentation.md)

---

## 🎭 Demo Scenarios

| User | Scenario | Expected Result |
|------|----------|-----------------|
| **Alice** | Good credit (Score: 85) | ✅ Loan approved, 120% collateral |
| **Bob** | Poor credit (DTI: 80%) | ❌ Rejected at Layer 1 |
| **Eve** | Model tampering | ❌ Caught at Layer 5 |
| **Mallory** | Data tampering | ❌ Caught at Layer 2 |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 🔗 Links

- **Repository**: [github.com/DIVYESH-HARI/zkredit](https://github.com/DIVYESH-HARI/zkredit)
- **Documentation**: See `/documentation` folder
- **Demo**: Run locally with `npm run dev:client`

---

<p align="center">
  Built with ❤️ for ETH Global Hackathon
</p>
