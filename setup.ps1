# Setup Script for ZKredit (Phase 1) - PowerShell
$ErrorActionPreference = "Stop"

Write-Host "Starting ZKredit Environment Setup..." -ForegroundColor Cyan

# 1. Check Dependencies
Write-Host "Checking dependencies..."
$missingDeps = $false

function Check-Cmd($cmd) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "✅ $cmd is installed." -ForegroundColor Green
    } else {
        Write-Host "❌ $cmd could not be found." -ForegroundColor Red
        return $true
    }
    return $false
}

if (Check-Cmd "node") { $missingDeps = $true }
if (Check-Cmd "python") { $missingDeps = $true }
if (Check-Cmd "forge") { $missingDeps = $true }
if (Check-Cmd "ezkl") { $missingDeps = $true }

if ($missingDeps) {
    Write-Host "⚠️  Some dependencies are missing." -ForegroundColor Yellow
    Write-Host "Foundry: https://book.getfoundry.sh/getting-started/installation"
    Write-Host "EZKL: cargo install ezkl (requires Rust)"
    $confirmation = Read-Host "Continue anyway? (y/n)"
    if ($confirmation -ne 'y') {
        exit
    }
}

# 2. Create Directory Structure
Write-Host "Creating directory structure..."
New-Item -ItemType Directory -Force -Path "contracts" | Out-Null
New-Item -ItemType Directory -Force -Path "client" | Out-Null
New-Item -ItemType Directory -Force -Path "circuits" | Out-Null
New-Item -ItemType Directory -Force -Path "mock-oracle" | Out-Null
New-Item -ItemType Directory -Force -Path "scripts" | Out-Null

# 3. Initialize Git
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
} else {
    Write-Host "Git already initialized."
}

# 4. Create .gitignore
if (-not (Test-Path ".gitignore")) {
    Write-Host "Creating .gitignore..."
    $gitignore = @"
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
"@
    Set-Content -Path ".gitignore" -Value $gitignore
}

# 5. Create root package.json
if (-not (Test-Path "package.json")) {
    Write-Host "Creating root package.json..."
    $packageJson = @"
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
"@
    Set-Content -Path "package.json" -Value $packageJson
}

# 6. Initialize Workspaces

# Client
if ((Get-ChildItem "client").Count -eq 0) {
    Write-Host "Initializing Client (React/Vite)..."
    # npm create vite needs to be automated or run inside.
    # We'll try running it inside.
    Push-Location client
    # create vite app in current dir (.)
    # Note: npm create vite@latest . -- --template react
    cmd /c "npm create vite@latest . -- --template react"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installing client dependencies..."
        npm install
        npm install wagmi viem @rainbow-me/rainbowkit eslint tailwindcss autoprefixer postcss
        npx tailwindcss init -p
    }
    Pop-Location
}

# Mock Oracle
if ((Get-ChildItem "mock-oracle").Count -eq 0) {
    Write-Host "Initializing Mock Oracle..."
    Push-Location mock-oracle
    cmd /c "npm init -y"
    npm install express cors ethers
    Pop-Location
}

# Contracts
if ((Get-ChildItem "contracts").Count -eq 0) {
    Write-Host "Initializing Contracts..."
    if (Get-Command force -ErrorAction SilentlyContinue) { # Typo check: forge
        forge init contracts --force --no-commit
        Push-Location contracts
        forge install OpenZeppelin/openzeppelin-contracts --no-commit
        Pop-Location
    } elseif (Get-Command forge -ErrorAction SilentlyContinue) {
        forge init contracts --force --no-commit
        Push-Location contracts
        forge install OpenZeppelin/openzeppelin-contracts --no-commit
        Pop-Location
    } else {
         Write-Host "⚠️  Forge not found, skipping 'forge init'." -ForegroundColor Yellow
    }
}

Write-Host "✅ Setup Complete!" -ForegroundColor Green
