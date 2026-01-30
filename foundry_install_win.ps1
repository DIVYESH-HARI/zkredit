<#
.SYNOPSIS
    Installs Foundry (forge, cast, anvil, chisel) on Windows.
.DESCRIPTION
    Downloads the latest nightly release from GitHub, extracts it to ~/.foundry/bin,
    and adds the directory to the user's PATH.
#>

$ErrorActionPreference = "Stop"

Write-Host "Installing Foundry (Windows)..." -ForegroundColor Cyan

# Define paths
$BaseDir = [System.Environment]::GetFolderPath("UserProfile")
$FoundryDir = Join-Path $BaseDir ".foundry"
$BinDir = Join-Path $FoundryDir "bin"
$ZipPath = Join-Path $FoundryDir "foundry.zip"

# Ensure directories exist
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# Download URL for the latest nightly build (Windows AMD64)
$DownloadUrl = "https://github.com/foundry-rs/foundry/releases/download/nightly/foundry_nightly_win32_amd64.zip"

Write-Host "Downloading latest Foundry binaries from: $DownloadUrl"
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
}
catch {
    Write-Error "Failed to download Foundry. Please check your internet connection or try installing via Cargo: cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil chisel"
    exit 1
}

Write-Host "Extracting to $BinDir..."
Expand-Archive -Path $ZipPath -DestinationPath $BinDir -Force

# Unblock the extracted files to prevent Windows SmartScreen issues
Get-ChildItem -Path "$BinDir\*" -Recurse | Unblock-File

# Cleanup zip
Remove-Item -Path $ZipPath -Force

# Add to PATH if not already present
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    Write-Host "Adding $BinDir to user PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:Path += ";$BinDir"
    Write-Host "Success! Foundry has been added to your PATH." -ForegroundColor Green
    Write-Host "You may need to restart your terminal for changes to take effect." -ForegroundColor Yellow
}
else {
    Write-Host "Foundry directory is already in your PATH." -ForegroundColor Green
}

Write-Host "Verifying installation..."
try {
    & "$BinDir\forge.exe" --version
    Write-Host "Foundry installed successfully!" -ForegroundColor Green
}
catch {
    Write-Warning "Could not verify 'forge --version'. You might need to restart your terminal."
}
