# ZKredit

ZK-ML DeFi Project.

## Quick Start (Windows)

### Prerequisites
- [Node.js v18+](https://nodejs.org/)
- [Python 3.10+](https://www.python.org/)
- [Rust](https://www.rust-lang.org/tools/install) (Required for EZKL & Foundry)
  - run `winget install Rustlang.Rustup` in PowerShell

### Installation

1. **Run the setup script (PowerShell)**:
   ```powershell
   ./setup.ps1
   ```
   *This script aims to set up the directory structure and initialize workspaces.*

2. **Install remaining dependencies**:
   If the setup script didn't install everything (common on fresh Windows setups):
   ```powershell
   # Install EZKL (requires Rust)
   cargo install ezkl

   # Install Foundry (requires Rust/Cargo)
   cargo install --git https://github.com/foundry-rs/foundry --profile local --force foundry-cli anvil chisel
   ```

3. **Install Node dependencies**:
   ```bash
   npm install
   ```

4. **Start Client**:
   ```bash
   npm run dev:client
   ```

## Architecture
- `contracts/`: Foundry Solidity smart contracts
- `circuits/`: EZKL ZK circuits & ONNX models
- `client/`: React/Vite Frontend
- `mock-oracle/`: Mock banking data provider (Node.js)
- `scripts/`: Python ML training & utility scripts
- `final_documentation.md`: **[COMPREHENSIVE PROJECT DOCUMENTATION](./final_documentation.md)** (Read this first!)

## Troubleshooting
- **Command 'cargo' not found**: 
  - Restart your terminal after installing Rust. 
  - Ensure `%USERPROFILE%\.cargo\bin` is in your PATH.
- **Execution Policy Errors**:
  - Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` to allow running scripts.
