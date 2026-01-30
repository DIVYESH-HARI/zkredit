// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ModelRegistry.sol";
import "../src/ConstraintRegistry.sol";
import "../src/ZKreditLendingPool.sol";
import "../src/mocks/MockVerifier.sol";

/**
 * @title DeployZKredit
 * @notice Deployment script for ZKredit contracts to Base Sepolia
 */
contract DeployZKredit is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_1");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ModelRegistry
        ModelRegistry modelRegistry = new ModelRegistry();
        console.log("ModelRegistry deployed at:", address(modelRegistry));
        
        // 2. Deploy ConstraintRegistry
        ConstraintRegistry constraintRegistry = new ConstraintRegistry();
        console.log("ConstraintRegistry deployed at:", address(constraintRegistry));
        
        // 3. Deploy MockVerifier (for testing - replace with real EZKL verifier later)
        MockVerifier mockVerifier = new MockVerifier(true);
        console.log("MockVerifier deployed at:", address(mockVerifier));
        
        // 4. Deploy ZKreditLendingPool
        ZKreditLendingPool lendingPool = new ZKreditLendingPool(
            address(mockVerifier),
            address(modelRegistry),
            address(constraintRegistry)
        );
        console.log("ZKreditLendingPool deployed at:", address(lendingPool));
        
        // 5. Commit demo model hash
        bytes32 demoModelHash = keccak256("demo_credit_model_v1.onnx");
        modelRegistry.commitModel(demoModelHash);
        console.log("Demo model committed with hash:", vm.toString(demoModelHash));
        
        vm.stopBroadcast();
        
        // Output deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network: Base Sepolia");
        console.log("ModelRegistry:", address(modelRegistry));
        console.log("ConstraintRegistry:", address(constraintRegistry));
        console.log("MockVerifier:", address(mockVerifier));
        console.log("ZKreditLendingPool:", address(lendingPool));
        console.log("==========================\n");
    }
}
