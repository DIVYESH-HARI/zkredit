# ZKredit Demo Quick Start

## One-Command Demo (Windows PowerShell)

```powershell
# Run both servers in parallel
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd client; npm run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd mock-oracle; npm run dev"

# Wait 3 seconds then open browser
Start-Sleep -Seconds 3
Start-Process "http://localhost:5173"
```

## Manual Start

### Terminal 1 - Client
```bash
cd client
npm run dev
```

### Terminal 2 - Mock Bank Oracle
```bash
cd mock-oracle  
npm run dev
```

### Open Browser
Navigate to: **http://localhost:5173**

## Pre-Loaded Test Accounts

| User | Credit | Income | DTI | Expected Result |
|------|--------|--------|-----|-----------------|
| Alice | Excellent (85) | $8,000 | 25% | ✅ 120% collateral |
| Bob | Poor (40) | $3,000 | 57% | ❌ Rejected |
| Charlie | Borderline (65) | $5,000 | 30% | ⚠️ 150% collateral |

## Demo Navigation

1. **🎭 Theater** - Guided demo sequences for judges
2. **🏦 Demo** - Interactive loan application
3. **🔬 Security Lab** - Attack simulation gallery
4. **🔍 Transparency** - Glass box model viewer

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "VITE not found" | `npm install` in client folder |
| Port 5173 busy | `npx kill-port 5173` |
| Oracle errors | Restart mock-oracle server |
| Wallet won't connect | Clear browser cache |

## Network Requirements

- Base Sepolia RPC: `https://sepolia.base.org`
- Test ETH: Get from [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
