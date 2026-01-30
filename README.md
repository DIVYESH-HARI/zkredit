# ZKredit

ZK-ML DeFi Project.

## Quick Start

### Prerequisites
- Node.js v18+
- Python 3.10+
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [EZKL](https://github.com/zkonduit/ezkl) (requires Rust)

### Installation

1. Run the setup script:
   ```bash
   ./setup.sh
   # OR for PowerShell
   ./setup.ps1
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start Client:
   ```bash
   npm run dev:client
   ```

## Architecture
- `contracts/`: Foundry Solidity smart contracts
- `circuits/`: EZKL ZK circuits & ONNX models
- `client/`: React/Vite Frontend
- `mock-oracle/`: Mock banking data provider (Node.js)
- `scripts/`: Python ML training & utility scripts

## Troubleshooting
- **Foundry/EZKL missing**: Install them manually if the script fails.
- **Foundry/EZKL missing**:
  - **Windows**: 
    1. Install Rust: `winget install Rustlang.Rustup`
    2. Refresh Env: `$env:PATH += ";$env:USERPROFILE\.cargo\bin"`
    3. Install EZKL: `cargo install ezkl`
    4. Install Foundry: `cargo install --git https://github.com/foundry-rs/foundry --profile local --force foundry-cli anvil chisel`

