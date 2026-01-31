# ZKredit - Privacy-Preserving DeFi Credit Scoring

## 🧠 What It Does
ZKredit lets borrowers **prove their creditworthiness** to DeFi lenders **without revealing financial data**. Good credit = lower collateral requirements.

---

## 🔑 Key Innovation

| Traditional DeFi | ZKredit |
|-----------------|---------|
| 150% collateral for everyone | 120% for good credit |
| No risk assessment | Real credit scoring |
| Data exposure to Plaid | Zero-knowledge proofs |
| Black box algorithms | Glass box transparency |

---

## 🛡️ 5-Layer Security

```
┌─────────────────────────────────────────┐
│ Layer 0: Anti-Replay (proof hash)       │
├─────────────────────────────────────────┤
│ Layer 1: Hard Constraints (DTI < 30%)   │
├─────────────────────────────────────────┤
│ Layer 2: Data Provenance (bank sig)     │
├─────────────────────────────────────────┤
│ Layer 3: ZK Proof Verification          │
├─────────────────────────────────────────┤
│ Layer 4: Output Bounds (score 0-100)    │
├─────────────────────────────────────────┤
│ Layer 5: Model Hash Consistency         │
└─────────────────────────────────────────┘
```

---

## 📊 Tech Stack

- **ZK Proofs**: EZKL + Halo2
- **Blockchain**: Base Sepolia (L2)
- **Frontend**: React + RainbowKit
- **Smart Contracts**: Foundry (Solidity)
- **ML Model**: PyTorch → ONNX → EZKL

---

## ✅ What We Built

- [x] 4 smart contracts deployed
- [x] 20 security tests passing
- [x] 5 attack vector defenses
- [x] Glass box model transparency
- [x] Judge-ready demo (8 min)

---

## 🛤️ Roadmap to Trustlessness

| Phase | Trust Assumption | Status |
|-------|------------------|--------|
| 1. Trusted Oracles | Mock bank | ✅ Live |
| 2. zkTLS | Cryptographic proof | 🔜 Q2 |
| 3. DAO Governance | Community controls | 📐 Designed |
| 4. Fully Trustless | Multi-source consensus | 🔮 Vision |

---

## 👥 Team

*[Add team names here]*

---

## 🔗 Links

- **Demo**: http://localhost:5173
- **GitHub**: github.com/[repo]
- **Contracts**: sepolia.basescan.org

---

*Built for ETHGlobal Hackathon 2026*
