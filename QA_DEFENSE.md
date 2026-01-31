# 🧑‍⚖️ ZKredit Q&A Defense Guide
## Anticipated Judge Questions & Answers

---

## 🔒 Trust & Security Questions

### Q1: "Isn't this just moving trust from banks to oracles?"

**Short Answer:**
> "Yes, for now. But we show a clear path to trustlessness via zkTLS in Phase 2."

**Detailed Answer:**
> "Currently we use signed attestations from a mock bank oracle. This is a stepping stone. In Phase 2, we integrate TLSNotary—a cryptographic protocol that proves data came from a real HTTPS connection to your bank, without trusting any intermediary. The oracle becomes a relay, not a trusted party."

---

### Q2: "Can't users reverse-engineer the model weights?"

**Short Answer:**
> "Yes, and that's intentional. Transparency prevents hidden discrimination."

**Detailed Answer:**
> "Our model weights are PUBLIC on IPFS. Anyone can download them, inspect them, and verify no discriminatory features exist. This is the opposite of traditional credit scoring where algorithms are 'black boxes.' We call ours a 'glass box.' Transparency isn't a bug—it's the feature."

---

### Q3: "What about model bias?"

**Short Answer:**
> "Public weights + DAO governance = community-audited fairness."

**Detailed Answer:**
> "Three defenses: (1) Weights are public, so researchers can audit for bias. (2) We use only financial features—no race, gender, or zipcode. (3) Phase 3 introduces DAO governance where the community votes on model updates. Bias becomes a community-solved problem, not a corporate secret."

---

### Q4: "Why would banks participate?"

**Short Answer:**
> "They don't need to—we use their existing APIs via TLSNotary."

**Detailed Answer:**
> "Banks never actively participate. TLSNotary captures data from existing bank APIs (like Plaid does today) but adds cryptographic proof. The bank doesn't even know a ZK proof was generated from their data. Zero integration required from banks."

---

## ⚡ Technical Questions

### Q5: "How long does ZK proof generation take?"

**Short Answer:**
> "~15-30 seconds in production. For demo, we simulate with 2-second delays."

**Detailed Answer:**
> "Using EZKL with Halo2 proofs, a typical credit score proof takes 15-30 seconds on consumer hardware. We're exploring GPU acceleration and recursive proofs to reduce this. For the hackathon demo, we simulate the process with realistic UI feedback."

---

### Q6: "What's the on-chain gas cost?"

**Short Answer:**
> "~300K gas for proof verification on Base Sepolia."

**Detailed Answer:**
> "EZKL-generated Halo2 proofs verify for approximately 300,000 gas on Base (~$0.02-0.05 at current gas prices). We chose Base for low fees. Future optimizations include proof aggregation for batch verification."

---

### Q7: "What happens if the ZK proof is invalid?"

**Short Answer:**
> "Transaction reverts. No loan issued. Collateral deposit slashed."

**Detailed Answer:**
> "Invalid proofs trigger our 5-layer defense:
> - Layer 0: Proof marked as used (anti-replay)
> - Layer 1: Constraint checks (DTI/income)
> - Layer 2: Bank signature verified
> - Layer 3: ZK proof math verification
> - Layer 4: Output bounds validated
> - Layer 5: Model hash confirmed
> 
> If any layer fails, the transaction reverts and the security deposit is slashed. Educational message explains why."

---

## 💰 Business & Economics Questions

### Q8: "How do lenders make money with lower collateral?"

**Short Answer:**
> "Lower collateral + higher volume = more capital efficiency."

**Detailed Answer:**
> "DeFi lenders today require 150% collateral, limiting who can borrow. With ZKredit:
> - Good credit users get 120% collateral (30% capital savings)
> - More people can borrow (larger market)
> - Default risk is assessed, not assumed
> 
> Lenders trade some over-collateralization for larger market access."

---

### Q9: "What's the competitive landscape?"

**Short Answer:**
> "We're first-to-market with ML-in-ZK for DeFi credit scoring."

**Detailed Answer:**
> "Existing solutions:
> - **Aave/Compound**: No credit scoring (150% for everyone)
> - **Goldfinch/Maple**: Off-chain underwriting (not trustless)
> - **Spectral**: On-chain credit scores (but limited to on-chain data)
> 
> ZKredit is unique: real-world bank data + ML model + ZK privacy + glass box transparency."

---

### Q10: "What's your go-to-market strategy?"

**Short Answer:**
> "Partner with existing DeFi lending protocols."

**Detailed Answer:**
> "Three-phase GTM:
> 1. **Hackathon Demo**: Prove technical feasibility
> 2. **Pilot Integration**: Partner with one lending protocol (e.g., Morpho, Euler)
> 3. **Protocol Standard**: Propose EIP for standardized credit proofs
> 
> We provide the credit verification layer; existing protocols provide liquidity."

---

## 🛡️ Attack-Specific Questions

### Q11: "What if someone creates a fake bank?"

**Short Answer:**
> "Bank addresses are registered on-chain. Only authorized oracles accepted."

**Detailed Answer:**
> "The ZKreditLendingPool contract has a registered bank oracle address. Signatures from any other address are rejected at Layer 2 (Data Provenance). In production with zkTLS, the TLSNotary proof includes the bank's actual TLS certificate—unforgeable."

---

### Q12: "Can the model owner rug-pull with a malicious model update?"

**Short Answer:**
> "Timelock + Glass Box = No sudden changes."

**Detailed Answer:**
> "Model updates go through:
> 1. New hash must be committed to ModelRegistry
> 2. 24-hour timelock before activation (Phase 2)
> 3. All weights publicly viewable before going live
> 4. DAO governance for approval (Phase 3)
> 
> No one can silently change the model."

---

## 📊 Demo-Specific Questions

### Q13: "Is this all simulated?"

**Short Answer:**
> "Smart contracts are real on Base Sepolia. Proofs are simulated."

**Detailed Answer:**
> "What's real:
> - Smart contracts deployed on Base Sepolia
> - 5-layer verification logic
> - 20 passing security tests (Foundry)
> - Wallet interactions via RainbowKit
> 
> What's simulated for hackathon:
> - ZK proof generation (would need EZKL server)
> - Bank oracle (mock server signing data)
> - TLSNotary integration (Phase 2 feature)"

---

## 💡 Quick Reference Card

| Question Theme | Key Phrase |
|----------------|------------|
| Trust | "Path to trustlessness via zkTLS" |
| Transparency | "Glass box, not black box" |
| Bias | "Public weights + DAO governance" |
| Speed | "15-30 seconds, optimizable" |
| Cost | "~$0.02 on Base" |
| Competition | "First ML-in-ZK for DeFi credit" |
| Attacks | "5-layer defense catches everything" |
