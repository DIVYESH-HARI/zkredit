/**
 * ZKredit Demo Recording Script
 * Automates browser actions for demo video recording
 * 
 * Usage: node scripts/record_demo.js
 * 
 * Prerequisites:
 * - npm install puppeteer
 * - Frontend running on localhost:5173
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const DEMO_URL = 'http://localhost:5173';
const SCREENSHOT_DIR = path.join(__dirname, '..', 'demo-screenshots');

// Ensure screenshot directory exists
if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function takeScreenshot(page, name) {
    const filepath = path.join(SCREENSHOT_DIR, `${name}.png`);
    await page.screenshot({ path: filepath, fullPage: false });
    console.log(`📸 Screenshot saved: ${name}.png`);
    return filepath;
}

async function runDemo() {
    console.log('\n' + '='.repeat(60));
    console.log('🎬 ZKredit Demo Recording Script');
    console.log('='.repeat(60) + '\n');

    const browser = await puppeteer.launch({
        headless: false, // Set to true for CI/CD
        defaultViewport: { width: 1920, height: 1080 },
        args: ['--start-maximized'],
    });

    const page = await browser.newPage();

    try {
        // ==============================
        // Scene 1: Landing Page
        // ==============================
        console.log('\n📍 Scene 1: Landing Page');
        await page.goto(DEMO_URL, { waitUntil: 'networkidle2' });
        await delay(2000);
        await takeScreenshot(page, '01_landing_page');

        // ==============================
        // Scene 2: Connect Wallet
        // ==============================
        console.log('\n📍 Scene 2: Connect Wallet');

        // Click connect wallet button (RainbowKit)
        const connectButton = await page.$('button:has-text("Connect")');
        if (connectButton) {
            await connectButton.click();
            await delay(1500);
            await takeScreenshot(page, '02_wallet_modal');

            // Close modal (escape key)
            await page.keyboard.press('Escape');
            await delay(500);
        } else {
            console.log('   ⚠️ Connect button not found, skipping...');
        }

        // ==============================
        // Scene 3: Alice - Happy Path
        // ==============================
        console.log('\n📍 Scene 3: Alice - Happy Path');

        // Select Alice from user cards
        const aliceCard = await page.$('[data-user="alice"], .user-card:first-child');
        if (aliceCard) {
            await aliceCard.click();
            await delay(1000);
            await takeScreenshot(page, '03_alice_selected');
        }

        // Set loan amount
        const amountInput = await page.$('input[type="range"], input[name="amount"]');
        if (amountInput) {
            await amountInput.click();
            await page.keyboard.type('5');
            await delay(500);
        }

        await takeScreenshot(page, '04_loan_form_filled');

        // Click Generate Proof / Apply button
        const applyButton = await page.$('button:has-text("Apply"), button:has-text("Generate")');
        if (applyButton) {
            await applyButton.click();
            console.log('   ⏳ Waiting for proof generation...');
            await delay(3000); // Wait for proof generation animation
            await takeScreenshot(page, '05_proof_generating');
            await delay(3000); // Wait for completion
            await takeScreenshot(page, '06_alice_success');
        }

        // ==============================
        // Scene 4: Bob - Sad Path
        // ==============================
        console.log('\n📍 Scene 4: Bob - Rejection');

        // Scroll to top
        await page.evaluate(() => window.scrollTo(0, 0));
        await delay(500);

        // Select Bob
        const bobCard = await page.$('[data-user="bob"], .user-card:nth-child(2)');
        if (bobCard) {
            await bobCard.click();
            await delay(1000);
            await takeScreenshot(page, '07_bob_selected');
        }

        // Click Apply
        const applyBtn2 = await page.$('button:has-text("Apply"), button:has-text("Generate")');
        if (applyBtn2) {
            await applyBtn2.click();
            await delay(3000);
            await takeScreenshot(page, '08_bob_rejected');
        }

        // ==============================
        // Scene 5: Attack Demo
        // ==============================
        console.log('\n📍 Scene 5: Security Demo');

        // Scroll to Attack Demo section
        await page.evaluate(() => {
            const attackDemo = document.querySelector('.attack-demo');
            if (attackDemo) attackDemo.scrollIntoView({ behavior: 'smooth' });
        });
        await delay(1000);
        await takeScreenshot(page, '09_attack_demo_section');

        // Click GIGO attack button
        const gigoButton = await page.$('button:has-text("Fake Data"), button:has-text("GIGO")');
        if (gigoButton) {
            await gigoButton.click();
            await delay(3000);
            await takeScreenshot(page, '10_attack_blocked');
        }

        // ==============================
        // Scene 6: Metrics Dashboard
        // ==============================
        console.log('\n📍 Scene 6: Metrics Dashboard');

        await page.evaluate(() => {
            const dashboard = document.querySelector('.metrics-dashboard');
            if (dashboard) dashboard.scrollIntoView({ behavior: 'smooth' });
        });
        await delay(2000); // Wait for animations
        await takeScreenshot(page, '11_metrics_comparison');

        // ==============================
        // Done!
        // ==============================
        console.log('\n' + '='.repeat(60));
        console.log('✅ Demo recording complete!');
        console.log(`📂 Screenshots saved to: ${SCREENSHOT_DIR}`);
        console.log('='.repeat(60) + '\n');

        // List all screenshots
        const screenshots = fs.readdirSync(SCREENSHOT_DIR).filter(f => f.endsWith('.png'));
        console.log('📸 Generated screenshots:');
        screenshots.forEach(s => console.log(`   - ${s}`));

    } catch (error) {
        console.error('❌ Error during demo:', error.message);
        await takeScreenshot(page, 'error_state');
    } finally {
        await delay(2000);
        await browser.close();
    }
}

// Instructions for video recording
function printInstructions() {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║                  Demo Recording Guide                      ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Option 1: Automated Screenshots                           ║
║  ─────────────────────────────────────────────────────────║
║  1. Start the frontend: cd client && npm run dev           ║
║  2. Run this script: node scripts/record_demo.js           ║
║  3. Screenshots saved to /demo-screenshots/                ║
║                                                            ║
║  Option 2: Manual Video Recording                          ║
║  ─────────────────────────────────────────────────────────║
║  1. Use OBS Studio or QuickTime Player                     ║
║  2. Set resolution to 1920x1080                            ║
║  3. Record the following scenarios:                        ║
║     a) Happy path: Alice gets approved (120% collateral)   ║
║     b) Sad path: Bob gets rejected (high DTI)              ║
║     c) Attack path: Tampering blocked                      ║
║                                                            ║
║  Tips:                                                     ║
║  - Move mouse slowly for visibility                        ║
║  - Pause 2-3 seconds after each action                     ║
║  - Highlight error messages with cursor                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
`);
}

// Main
printInstructions();

// Check if puppeteer is available
try {
    require.resolve('puppeteer');
    runDemo().catch(console.error);
} catch (e) {
    console.log('⚠️ Puppeteer not installed. Install with: npm install puppeteer');
    console.log('   Then run: node scripts/record_demo.js');
    process.exit(0);
}
