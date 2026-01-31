# ZKredit Circuit Generation Script (PowerShell)
# Generates ZK circuit, proving keys, and Solidity verifier from ONNX model

$ErrorActionPreference = "Stop"

Write-Host "=" * 60
Write-Host "ZKredit EZKL Circuit Generation"
Write-Host "=" * 60

# Set working directory
$circuitsDir = $PSScriptRoot
Set-Location $circuitsDir

# Verify model.onnx exists
if (-not (Test-Path "model.onnx")) {
    Write-Host "`n[ERROR] model.onnx not found!"
    Write-Host "        Run 'python scripts/train_model.py' first."
    exit 1
}

Write-Host "`n[1/5] Downloading SRS (Structured Reference String)..."
Write-Host "      This may take a few minutes on first run..."
ezkl get-srs --srs-path kzg.srs --logrows 17
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[ERROR] Failed to download SRS"
    exit 1 
}
Write-Host "      SRS downloaded successfully."

Write-Host "`n[2/5] Generating circuit settings..."
ezkl gen-settings -M model.onnx --settings-path settings.json
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[ERROR] Failed to generate settings"
    exit 1 
}
Write-Host "      Settings saved to settings.json"

Write-Host "`n[3/5] Compiling ONNX model to circuit..."
ezkl compile-circuit -M model.onnx -S settings.json --compiled-circuit model.ezkl
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[ERROR] Failed to compile circuit"
    exit 1 
}
Write-Host "      Circuit compiled to model.ezkl"

Write-Host "`n[4/5] Generating proving and verification keys..."
Write-Host "      This may take a minute..."
ezkl setup -M model.ezkl --srs-path kzg.srs --vk-path vk.key --pk-path pk.key
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[ERROR] Failed to generate keys"
    exit 1 
}
Write-Host "      Keys saved: vk.key, pk.key"

Write-Host "`n[5/5] Generating Solidity verifier contract..."
$verifierPath = "..\contracts\src\Verifier.sol"
ezkl create-evm-verifier --srs-path kzg.srs --vk-path vk.key --sol-code-path $verifierPath
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[ERROR] Failed to generate verifier"
    exit 1 
}
Write-Host "      Verifier saved to: $verifierPath"

Write-Host "`n" + "=" * 60
Write-Host "Circuit Generation Complete!"
Write-Host "=" * 60

Write-Host "`nGenerated files:"
Write-Host "  - kzg.srs          (Structured Reference String)"
Write-Host "  - settings.json    (Circuit settings)"
Write-Host "  - model.ezkl       (Compiled circuit)"
Write-Host "  - vk.key           (Verification key)"
Write-Host "  - pk.key           (Proving key)"
Write-Host "  - Verifier.sol     (Solidity verifier)"

Write-Host "`nNext steps:"
Write-Host "  1. cd ..\contracts"
Write-Host "  2. forge build     (verify Verifier.sol compiles)"
Write-Host "  3. Update ZKreditLendingPool to use Verifier.sol"
