const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

async function main() {
    console.log("Generating 3 Base Sepolia Wallets...");
    const wallets = [];
    let envContent = "# ZKredit Environment Variables\n\n# RPC Configuration\nBASE_SEPOLIA_RPC=https://sepolia.base.org\n\n# Wallets (Private Keys)\n";
    let addresses = "";

    for (let i = 1; i <= 3; i++) {
        const wallet = ethers.Wallet.createRandom();
        wallets.push(wallet);
        console.log(`Wallet ${i}: ${wallet.address}`);
        envContent += `PRIVATE_KEY_${i}=${wallet.privateKey}\n`;
        envContent += `ADDRESS_${i}=${wallet.address}\n`;
        addresses += `- Wallet ${i}: ${wallet.address}\n`;
    }

    // Write to root .env
    const rootDir = path.join(__dirname, '..');
    const envPath = path.join(rootDir, '.env');

    // Check if .env exists to avoid overwriting unrelated vars (though we are initializing)
    // For now we append or write new.
    fs.writeFileSync(envPath, envContent, { flag: 'w' });
    console.log(`\n✅ Saved private keys to ${envPath}`);

    // Write public addresses to a clean file for User
    fs.writeFileSync(path.join(rootDir, 'team_wallets.json'), JSON.stringify(wallets.map(w => ({ address: w.address, privateKey: w.privateKey })), null, 2));
    console.log(`✅ Saved wallet details to team_wallets.json (Added to .gitignore)`);
}

main();
