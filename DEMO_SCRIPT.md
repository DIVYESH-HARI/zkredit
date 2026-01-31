# 🧑‍⚖️ ZKredit Judge's Demo Script
## Total Time: 8 Minutes

---

## ⏱️ 0:00-0:30 | The Problem (30 sec)

**Script:**
> "DeFi lending today requires 150% over-collateralization because protocols have NO way to assess borrower risk. You could be Warren Buffett or a fresh wallet—same 150%."

**Show:** Traditional DeFi lending interface (Aave/Compound)

**Key Point:** On-chain data tells us nothing about real-world creditworthiness.

---

## ⏱️ 0:30-1:00 | ZKredit Solution (30 sec)

**Script:**
> "ZKredit lets you PROVE your creditworthiness using real bank data, WITHOUT revealing that data. Good credit? Get only 120% collateral requirements."

**Show:** Click "🎭 Theater" tab

**Key Point:** Privacy-preserving credit scoring using Zero-Knowledge proofs.

---

## ⏱️ 1:00-3:00 | Demo 1: Honest Alice (2 min)

**Script:**
> "Watch Alice, who has good credit, get a better deal."

### Steps:
1. Click "**Honest Alice**" sequence card
2. **Step 1 - Connect Wallet:** Show wallet connects
3. **Step 2 - Fetch Bank Data:** "Bank signs attestation of Alice's real income/debt"
4. **Step 3 - Generate ZK Proof:** "Credit model runs LOCALLY on her device"
5. **Step 4 - 5-Layer Verification:** Show all 5 green checkmarks
6. **Step 5 - Loan Approved:** "Alice gets 120% collateral—30% LESS than standard!"

**Key Point:** Alice's actual income was never exposed to the blockchain.

---

## ⏱️ 3:00-5:30 | Demo 2: Attack Gallery (2.5 min)

**Script:**
> "But what about attackers? Let's try to break the system."

### Click "🔬 Security Lab" tab

**Attack 1: GIGO (30 sec)**
> "Mallory forges income data claiming $100K when she earns $3K..."
- Click "Execute Attack"
- Show: ❌ BLOCKED at Layer 1 - "Signature verification failed"

**Attack 2: Model Tampering (30 sec)**
> "Mallory uses a rigged model that always outputs high scores..."
- Click "Execute Attack"  
- Show: ❌ BLOCKED at Layer 5 - "Model hash mismatch"

**Attack 3: Constraint Evasion (30 sec)**
> "Mallory tries to bypass the 30% DTI limit..."
- Click "Execute Attack"
- Show: ❌ BLOCKED at Layer 1 - "DTI exceeds maximum"

**Attack 4: Oracle Compromise (30 sec)**
> "Mallory compromises the bank oracle..."
- Click "Execute Attack"
- Show: ❌ BLOCKED at Layer 2 - "Invalid bank signature"

**Key Point:** Every attack caught by a different security layer. Defense in depth!

---

## ⏱️ 5:30-7:00 | Demo 3: Transparency Tour (1.5 min)

**Script:**
> "But how do users TRUST the credit model isn't rigged? Everything is verifiable."

### Click "🔍 Transparency" tab

**Show 1: Model Weights (30 sec)**
> "The EXACT neural network weights are on IPFS. Anyone can download and verify."
- Show the model hash and IPFS link

**Show 2: Constraint Registry (30 sec)**
> "The lending rules—30% max DTI, $3K min income—are all on-chain."
- Click "View on BaseScan"

**Show 3: Security Logs (30 sec)**  
> "Every attack attempt is logged. The watchdog never sleeps."
- Show attacks prevented count and slashed ETH

**Key Point:** Not a black box. Glass box. Verify, don't trust.

---

## ⏱️ 7:00-8:00 | Wrap-Up & Q&A Prep (1 min)

**Script:**
> "ZKredit: Privacy-preserving credit scoring for DeFi. Better rates for good borrowers. Complete security for lenders. Total transparency for everyone."

### Quick Stats:
- 🧪 20 security tests passing
- 🛡️ 5-layer verification
- 📊 Glass box model weights
- ⛓️ Deployed on Base Sepolia

---

## 🔧 Pre-Demo Checklist

- [ ] Wallet connected with test ETH
- [ ] Dev server running (`npm run dev`)
- [ ] Mock oracle running (`npm run dev:oracle`)
- [ ] Chrome DevTools closed (cleaner UI)
- [ ] Browser zoom at 90% for full view

## 🆘 Backup Plans

| Issue | Solution |
|-------|----------|
| Network slow | Use pre-recorded sequence |
| Wallet fails | Show static screenshots |
| Build breaks | `git stash && git checkout main` |

## 📝 Common Judge Questions

**Q: "How does the bank attestation work?"**
> "In production, we use TLSNotary—cryptographic proof that the data came from an HTTPS connection to your bank. For this demo, we simulate with ECDSA signatures."

**Q: "What if the model is biased?"**
> "The weights are PUBLIC. Anyone can audit them. We're also building DAO governance for constraint updates."

**Q: "Why not just use centralized services?"**
> "They see all your data. We see NOTHING—only that you passed the checks."
