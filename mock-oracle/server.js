/**
 * Mock Bank Oracle Server
 * Simulates TLSNotary attestations for ZKredit demo
 * 
 * In production, this would be actual bank infrastructure with real TLSNotary proofs.
 * For hackathon demo, we sign financial data with ECDSA to prove authenticity.
 */

import express from 'express';
import cors from 'cors';
import { ethers } from 'ethers';

const app = express();
app.use(cors());
app.use(express.json());

// Mock "bank" private key - in production this would be actual bank infrastructure
// Using a deterministic key for demo purposes
const BANK_PRIVATE_KEY = process.env.BANK_KEY ||
    "0x1111111111111111111111111111111111111111111111111111111111111111";
const BANK_WALLET = new ethers.Wallet(BANK_PRIVATE_KEY);

console.log(`🏦 Bank Oracle Address: ${BANK_WALLET.address}`);

// Mock user database - simulates bank's customer data
const USER_DATA = {
    "alice": {
        name: "Alice Johnson",
        income: BigInt(8000) * BigInt(10 ** 18),     // $8,000/month in wei-like format
        debt: BigInt(2000) * BigInt(10 ** 18),       // $2,000 outstanding debt
        dti: 2500,                                  // 25% DTI in basis points
        employment_years: 5,
        credit_history_score: 85,
        account_age_months: 48,
        on_time_payments: 47,
        description: "Good credit - should qualify for 120% collateral"
    },
    "bob": {
        name: "Bob Smith",
        income: BigInt(3000) * BigInt(10 ** 18),     // $3,000/month
        debt: BigInt(4000) * BigInt(10 ** 18),       // $4,000 outstanding debt
        dti: 5700,                                  // 57% DTI
        employment_years: 1,
        credit_history_score: 40,
        account_age_months: 12,
        on_time_payments: 8,
        description: "Bad credit - will likely be rejected"
    },
    "charlie": {
        name: "Charlie Davis",
        income: BigInt(5000) * BigInt(10 ** 18),     // $5,000/month
        debt: BigInt(1500) * BigInt(10 ** 18),       // $1,500 outstanding debt
        dti: 3000,                                  // 30% DTI - borderline
        employment_years: 3,
        credit_history_score: 65,
        account_age_months: 36,
        on_time_payments: 34,
        description: "Borderline credit - may qualify with standard collateral"
    }
};

/**
 * GET /api/users
 * Returns list of available test users
 */
app.get('/api/users', (req, res) => {
    const users = Object.entries(USER_DATA).map(([id, data]) => ({
        id,
        name: data.name,
        description: data.description
    }));
    res.json({ users });
});

/**
 * POST /api/financial-data
 * Returns signed financial attestation for a user
 * 
 * This simulates what TLSNotary would provide - cryptographic proof
 * that the data came from an authentic source (the bank).
 */
app.post('/api/financial-data', async (req, res) => {
    try {
        const { userId, address, mode } = req.body;

        if (!userId || !address) {
            return res.status(400).json({
                error: "Missing required fields: userId, address"
            });
        }

        const data = USER_DATA[userId.toLowerCase()];
        if (!data) {
            return res.status(404).json({
                error: `User '${userId}' not found. Available: ${Object.keys(USER_DATA).join(', ')}`
            });
        }

        // Validate Ethereum address
        if (!ethers.isAddress(address)) {
            return res.status(400).json({
                error: "Invalid Ethereum address"
            });
        }

        // Create message hash for signing
        // This matches what the smart contract will verify
        const abiCoder = ethers.AbiCoder.defaultAbiCoder();
        const messageHash = ethers.keccak256(
            abiCoder.encode(
                ['address', 'uint256', 'uint256', 'uint256', 'uint256'],
                [
                    address,
                    data.income.toString(),
                    data.debt.toString(),
                    data.dti,
                    data.credit_history_score
                ]
            )
        );

        // Sign the message
        let signature;
        let signerAddress;

        if (mode === 'compromised') {
            // ATTACK SIMULATION: Sign with a random rogue key
            const rogueWallet = ethers.Wallet.createRandom();
            signature = await rogueWallet.signMessage(ethers.getBytes(messageHash));
            signerAddress = rogueWallet.address;
            console.log(`⚠️ ATTACK: Generating FORGED signature for ${userId} using rogue key ${signerAddress.slice(0, 10)}...`);
        } else {
            // NORMAL: Sign with authorized bank key
            signature = await BANK_WALLET.signMessage(ethers.getBytes(messageHash));
            signerAddress = BANK_WALLET.address;
            console.log(`📜 Signed attestation for ${userId} -> ${address.slice(0, 10)}...`);
        }

        // Prepare response data (convert BigInts to strings for JSON)
        const responseData = {
            income: data.income.toString(),
            debt: data.debt.toString(),
            dti: data.dti,
            credit_history_score: data.credit_history_score,
            employment_years: data.employment_years,
            account_age_months: data.account_age_months,
            on_time_payments: data.on_time_payments
        };

        res.json({
            success: true,
            data: responseData,
            attestation: {
                signature,
                messageHash,
                bankAddress: signerAddress, // Return the actual signer (so frontend can see mismatch)
                timestamp: Date.now(),
                expiresAt: Date.now() + 3600000 // 1 hour validity
            }
        });

    } catch (error) {
        console.error('Error processing request:', error);
        res.status(500).json({
            error: "Internal server error",
            details: error.message
        });
    }
});

/**
 * POST /api/verify-signature
 * Utility endpoint to verify a signature (for debugging)
 */
app.post('/api/verify-signature', async (req, res) => {
    try {
        const { messageHash, signature } = req.body;

        const recoveredAddress = ethers.verifyMessage(
            ethers.getBytes(messageHash),
            signature
        );

        res.json({
            valid: recoveredAddress.toLowerCase() === BANK_WALLET.address.toLowerCase(),
            recoveredAddress,
            expectedAddress: BANK_WALLET.address
        });
    } catch (error) {
        res.status(400).json({ error: "Invalid signature format" });
    }
});

/**
 * GET /health
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        bankAddress: BANK_WALLET.address,
        availableUsers: Object.keys(USER_DATA)
    });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════╗
║         🏦 ZKredit Mock Bank Oracle 🏦            ║
╠═══════════════════════════════════════════════════╣
║  Server running on http://localhost:${PORT}          ║
║  Bank Address: ${BANK_WALLET.address.slice(0, 20)}... ║
║                                                   ║
║  Available endpoints:                             ║
║    GET  /api/users         - List test users      ║
║    POST /api/financial-data - Get signed data     ║
║    GET  /health            - Health check         ║
╚═══════════════════════════════════════════════════╝
    `);
});
