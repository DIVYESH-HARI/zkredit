// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SecurityRegistry
 * @notice Watchdog contract that tracks attack attempts and slashing events
 * @dev Part of the Triple-Registry "Constraint Sandwich" architecture
 * 
 * ARCHITECTURE OVERVIEW:
 * ┌─────────────────────────────────────────────────────────────┐
 * │                    CONSTRAINT SANDWICH                       │
 * ├─────────────────────────────────────────────────────────────┤
 * │  Layer 1: ModelRegistry (Glass Box)                         │
 * │     └── Stores keccak256(modelWeights)                      │
 * │     └── Ensures only authorized models generate proofs       │
 * ├─────────────────────────────────────────────────────────────┤
 * │  Layer 2: ConstraintRegistry (Iron Rules)                   │
 * │     └── DTI < 30%, minIncome > 5000, minCreditScore > 70    │
 * │     └── Immutable lending constraints                        │
 * ├─────────────────────────────────────────────────────────────┤
 * │  Layer 3: SecurityRegistry (Watchdog)                        │
 * │     └── Tracks attack attempts                               │
 * │     └── Records slashing events                              │
 * │     └── Monitors suspicious activity                         │
 * └─────────────────────────────────────────────────────────────┘
 * 
 * ATTACK VECTORS MONITORED:
 * 1. GIGO - Garbage In, Garbage Out (forged bank statements)
 * 2. Model Tampering - Unauthorized weight manipulation
 * 3. Constraint Evasion - DTI bypass attempts
 * 4. Replay Attack - Proof recycling
 * 5. Oracle Compromise - Signature forgery
 */
contract SecurityRegistry {
    // ============ State Variables ============
    address public owner;
    uint256 public totalAttacksBlocked;
    uint256 public totalSlashingEvents;
    
    // Attack type enumeration
    enum AttackType {
        GIGO,               // Forged bank statement / fake data
        MODEL_TAMPERING,    // Weight manipulation
        CONSTRAINT_EVASION, // DTI bypass attempt
        REPLAY_ATTACK,      // Proof recycling
        ORACLE_COMPROMISE   // Signature forgery
    }
    
    // Attack record structure
    struct AttackRecord {
        address attacker;
        AttackType attackType;
        bytes32 proofHash;
        string details;
        uint256 timestamp;
        bool slashed;
    }
    
    // Slashing record structure
    struct SlashingEvent {
        address attacker;
        uint256 amount;
        AttackType reason;
        uint256 timestamp;
    }
    
    // Storage
    mapping(address => AttackRecord[]) public attackHistory;
    mapping(address => uint256) public attackCount;
    mapping(address => bool) public blacklisted;
    SlashingEvent[] public slashingEvents;
    
    // ============ Events ============
    event AttackBlocked(
        address indexed attacker,
        AttackType attackType,
        bytes32 proofHash,
        string details,
        uint256 timestamp
    );
    
    event AddressBlacklisted(
        address indexed attacker,
        uint256 totalAttacks,
        uint256 timestamp
    );
    
    event SlashingExecuted(
        address indexed attacker,
        uint256 amount,
        AttackType reason,
        uint256 timestamp
    );
    
    event AttackerRehabbed(
        address indexed attacker,
        uint256 timestamp
    );
    
    // ============ Modifiers ============
    modifier onlyOwner() {
        require(msg.sender == owner, "SecurityRegistry: not owner");
        _;
    }
    
    // ============ Constructor ============
    constructor() {
        owner = msg.sender;
    }
    
    // ============ Attack Recording ============
    
    /**
     * @notice Record a blocked attack attempt
     * @param _attacker Address of the attacker
     * @param _attackType Type of attack attempted
     * @param _proofHash Hash of the invalid proof
     * @param _details Human-readable details about the attack
     */
    function recordAttack(
        address _attacker,
        AttackType _attackType,
        bytes32 _proofHash,
        string calldata _details
    ) external {
        AttackRecord memory record = AttackRecord({
            attacker: _attacker,
            attackType: _attackType,
            proofHash: _proofHash,
            details: _details,
            timestamp: block.timestamp,
            slashed: false
        });
        
        attackHistory[_attacker].push(record);
        attackCount[_attacker]++;
        totalAttacksBlocked++;
        
        emit AttackBlocked(_attacker, _attackType, _proofHash, _details, block.timestamp);
        
        // Auto-blacklist after 3 attacks
        if (attackCount[_attacker] >= 3 && !blacklisted[_attacker]) {
            blacklisted[_attacker] = true;
            emit AddressBlacklisted(_attacker, attackCount[_attacker], block.timestamp);
        }
    }
    
    /**
     * @notice Convenience function to record GIGO attack
     */
    function recordGIGOAttack(address _attacker, bytes32 _proofHash) external {
        this.recordAttack(_attacker, AttackType.GIGO, _proofHash, "Forged bank statement / invalid data");
    }
    
    /**
     * @notice Convenience function to record model tampering
     */
    function recordModelTampering(address _attacker, bytes32 _proofHash) external {
        this.recordAttack(_attacker, AttackType.MODEL_TAMPERING, _proofHash, "Invalid model hash");
    }
    
    /**
     * @notice Convenience function to record constraint evasion
     */
    function recordConstraintEvasion(address _attacker, bytes32 _proofHash) external {
        this.recordAttack(_attacker, AttackType.CONSTRAINT_EVASION, _proofHash, "DTI/Income constraint bypass attempt");
    }
    
    /**
     * @notice Convenience function to record replay attack
     */
    function recordReplayAttack(address _attacker, bytes32 _proofHash) external {
        this.recordAttack(_attacker, AttackType.REPLAY_ATTACK, _proofHash, "Proof already used");
    }
    
    /**
     * @notice Convenience function to record oracle compromise
     */
    function recordOracleCompromise(address _attacker, bytes32 _proofHash) external {
        this.recordAttack(_attacker, AttackType.ORACLE_COMPROMISE, _proofHash, "Invalid oracle signature");
    }
    
    // ============ Slashing ============
    
    /**
     * @notice Execute slashing for repeated offenders
     * @param _attacker Address to slash
     * @param _amount Amount to slash (from collateral)
     * @param _reason Reason for slashing
     */
    function executeSlashing(
        address _attacker,
        uint256 _amount,
        AttackType _reason
    ) external onlyOwner {
        SlashingEvent memory slashing = SlashingEvent({
            attacker: _attacker,
            amount: _amount,
            reason: _reason,
            timestamp: block.timestamp
        });
        
        slashingEvents.push(slashing);
        totalSlashingEvents++;
        
        emit SlashingExecuted(_attacker, _amount, _reason, block.timestamp);
    }
    
    // ============ Blacklist Management ============
    
    /**
     * @notice Manually blacklist an address
     */
    function blacklistAddress(address _attacker) external onlyOwner {
        blacklisted[_attacker] = true;
        emit AddressBlacklisted(_attacker, attackCount[_attacker], block.timestamp);
    }
    
    /**
     * @notice Rehabilitate an address (remove from blacklist)
     */
    function rehabilitateAddress(address _attacker) external onlyOwner {
        blacklisted[_attacker] = false;
        emit AttackerRehabbed(_attacker, block.timestamp);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Check if an address is blacklisted
     */
    function isBlacklisted(address _address) external view returns (bool) {
        return blacklisted[_address];
    }
    
    /**
     * @notice Get attack count for an address
     */
    function getAttackCount(address _address) external view returns (uint256) {
        return attackCount[_address];
    }
    
    /**
     * @notice Get attack history for an address
     */
    function getAttackHistory(address _address) external view returns (AttackRecord[] memory) {
        return attackHistory[_address];
    }
    
    /**
     * @notice Get total slashing events
     */
    function getSlashingEventsCount() external view returns (uint256) {
        return slashingEvents.length;
    }
    
    /**
     * @notice Get security stats
     */
    function getSecurityStats() external view returns (
        uint256 attacks,
        uint256 slashings
    ) {
        return (totalAttacksBlocked, totalSlashingEvents);
    }
    
    /**
     * @notice Get attack type name as string
     */
    function getAttackTypeName(AttackType _type) external pure returns (string memory) {
        if (_type == AttackType.GIGO) return "GIGO (Forged Data)";
        if (_type == AttackType.MODEL_TAMPERING) return "Model Tampering";
        if (_type == AttackType.CONSTRAINT_EVASION) return "Constraint Evasion";
        if (_type == AttackType.REPLAY_ATTACK) return "Replay Attack";
        if (_type == AttackType.ORACLE_COMPROMISE) return "Oracle Compromise";
        return "Unknown";
    }
}
