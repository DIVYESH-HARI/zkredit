#!/bin/bash
set -e

# Setup Script for ZKredit (Phase 1)

echo "Starting ZKredit Environment Setup..."

# 1. Check Dependencies
echo "Checking dependencies..."
MISSING_DEPS=0

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 could not be found."
        MISSING_DEPS=1
    else
        echo "✅ $1 is installed."
    fi
}

check_cmd "node"
check_cmd "python3" # Or python
check_cmd "forge"
check_cmd "ezkl"

if [ $MISSING_DEPS -eq 1 ]; then
    echo "⚠️  Some dependencies are missing. Please install them before proceeding."
    echo "Foundry: https://book.getfoundry.sh/getting-started/installation"
    echo "EZKL: cargo install ezkl (requires Rust)"
    # We don't exit here to allow scaffolding even if tools are missing, 
    # but strictly speaking validation steps will fail.
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 2. Create Directory Structure
echo "Creating directory structure..."
mkdir -p contracts
mkdir -p client
mkdir -p circuits
mkdir -p mock-oracle
mkdir -p scripts

# 3. Initialize Git
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
else
    echo "Git already initialized."
fi

# 4. Create .gitignore (if not exists)
if [ ! -f ".gitignore" ]; then
    echo "Creating .gitignore..."
    cat <<EOF > .gitignore
# Node
**/node_modules
**/cache
**/out
**/dist
**/.env
.DS_Store

# Python
__pycache__/
*.pyc
model.onnx
*.pt

# ZK
*.pk
*.vk
*.srs
witness.json
proof.json

# IDE
.vscode/
.idea/
EOF
fi

# 5. Create root package.json
if [ ! -f "package.json" ]; then
    echo "Creating root package.json..."
    cat <<EOF > package.json
{
  "name": "zkredit-monorepo",
  "private": true,
  "workspaces": [
    "client",
    "mock-oracle"
  ],
  "scripts": {
    "dev:client": "npm run dev --workspace=client",
    "dev:oracle": "npm run dev --workspace=mock-oracle"
  }
}
EOF
fi

# 6. Initialize Workspaces (Interactive/Automated)

# Client (React/Vite)
if [ -z "$(ls -A client)" ]; then
    echo "Initializing Client (React/Vite)..."
    # Using npm create vite (using template flag to avoid prompt if possible)
    # But often requires manual interaction or creating inside. 
    # We'll simulate by creating the files directly or running the command.
    # The prompt says: npm create vite@latest client -- --template react
    # Note: npm create vite targetting an existing empty dir 'client' might warn.
    # We will run it in the root against 'client'.
    npm create vite@latest client -- --template react || echo "⚠️ Failed to create vite app automatically."
    
    # Install deps
    cd client
    echo "Installing client dependencies..."
    npm install
    npm install wagmi viem @rainbow-me/rainbowkit eslint tailwindcss autoprefixer postcss
    npx tailwindcss init -p
    cd ..
else
    echo "Client directory not empty, skipping initialization."
fi

# Mock Oracle
if [ -z "$(ls -A mock-oracle)" ]; then
    echo "Initializing Mock Oracle..."
    cd mock-oracle
    npm init -y
    npm install express cors ethers
    cd ..
else
    echo "Mock Oracle directory not empty, skipping initialization."
fi

# Contracts (Foundry)
if [ -z "$(ls -A contracts)" ]; then
    echo "Initializing Contracts..."
    if command -v forge &> /dev/null; then
        # forge init contracts --force because dir exists
        forge init contracts --force --no-commit
        cd contracts
        forge install OpenZeppelin/openzeppelin-contracts --no-commit
        cd ..
    else
        echo "⚠️  Forge not found, skipping 'forge init'. Please run 'forge init contracts' manually."
    fi
else
    echo "Contracts directory not empty, skipping initialization."
fi

echo "✅ Setup Complete!"
echo "Next Steps:"
echo "1. Configure .env (see README.md)"
echo "2. Run 'npm install' in root"
