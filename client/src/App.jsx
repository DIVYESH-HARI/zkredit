/**
 * ZKredit - Privacy-Preserving DeFi Lending
 * Main Application Component with zkTLS Proof of Concept
 */

import { useState } from 'react';
import './index.css';

// Mock Oracle API URL
const API_URL = 'http://localhost:3001';

// On-chain Model Hash (from ModelRegistry)
const OFFICIAL_MODEL_HASH = '0x7d8f3e2a9c1b4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e';
const TAMPERED_MODEL_HASH = '0xDEADBEEFCAFEBABE1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF';

// Test Users including Attack Demos
const TEST_USERS = [
  {
    id: 'alice',
    name: 'Alice Johnson',
    emoji: '👩‍💼',
    description: 'Excellent Credit - High income, low debt',
    attackType: null,
  },
  {
    id: 'bob',
    name: 'Bob Smith',
    emoji: '👨',
    description: 'Poor Credit - Low income, high debt',
    attackType: null,
  },
  {
    id: 'charlie',
    name: 'Charlie Davis',
    emoji: '👨‍🔧',
    description: 'Fair Credit - Medium profile',
    attackType: null,
  },
  {
    id: 'eve',
    name: '🔓 Eve (Attacker)',
    emoji: '🦹‍♀️',
    description: 'MODEL TAMPERING - Uses modified ML model',
    attackType: 'model_tampering',
    isAttack: true,
  },
  {
    id: 'mallory',
    name: '🔓 Mallory (Attacker)',
    emoji: '🦹',
    description: 'DATA TAMPERING - Modifies financial data',
    attackType: 'data_tampering',
    isAttack: true,
  },
];

// Step definitions
const STEPS = [
  { id: 1, title: 'Bank Data', icon: '🏦' },
  { id: 2, title: 'zkTLS Proof', icon: '🔒' },
  { id: 3, title: 'ML Score', icon: '🧠' },
  { id: 4, title: 'ZK Proof', icon: '🔐' },
  { id: 5, title: 'Verification', icon: '✅' },
];

// Verification layers
const LAYERS = [
  { id: 0, name: 'Anti-Replay Prevention', desc: 'Ensures proof is unique and not reused' },
  { id: 1, name: 'Hard Constraints Check', desc: 'DTI < 30%, Income > minimum threshold' },
  { id: 2, name: 'Data Provenance', desc: 'Verifies bank signature on financial data' },
  { id: 3, name: 'ZK Proof Verification', desc: 'Validates the zero-knowledge proof' },
  { id: 4, name: 'Model Hash Match', desc: 'Confirms ML model integrity' },
];

// TLS Handshake Steps
const TLS_HANDSHAKE_STEPS = [
  { id: 1, name: 'Client Hello', desc: 'Browser initiates TLS connection', direction: 'right' },
  { id: 2, name: 'Server Hello + Certificate', desc: 'Bank sends SSL certificate', direction: 'left' },
  { id: 3, name: 'Key Exchange', desc: 'Secure key negotiation', direction: 'right' },
  { id: 4, name: 'Encrypted Session', desc: 'AES-256-GCM tunnel established', direction: 'both' },
  { id: 5, name: 'TLSNotary Proof', desc: 'Session proof generated', direction: 'proof' },
];

// Header Component
function Header() {
  return (
    <header className="header">
      <div className="container header-content">
        <div className="logo">
          <div className="logo-icon">🔐</div>
          <div className="logo-text">
            <h1>ZKredit</h1>
            <span>Privacy-Preserving DeFi Lending</span>
          </div>
        </div>
        <div style={{
          padding: '8px 16px',
          background: 'var(--color-bg-glass)',
          borderRadius: '8px',
          border: '1px solid var(--color-border)',
          fontSize: '14px',
          color: 'var(--color-text-secondary)'
        }}>
          🌐 Base Sepolia Testnet
        </div>
      </div>
    </header>
  );
}

// Progress Stepper Component
function ProgressStepper({ currentStep, completedSteps, failedStep }) {
  return (
    <div className="stepper">
      {STEPS.map((step, index) => (
        <div key={step.id} className="stepper-step">
          <div
            className={`stepper-circle ${failedStep === step.id
              ? 'failed'
              : completedSteps.includes(step.id)
                ? 'complete'
                : currentStep === step.id
                  ? 'active'
                  : 'inactive'
              }`}
            style={failedStep === step.id ? { background: 'var(--color-error)', boxShadow: '0 0 20px rgba(239, 68, 68, 0.5)' } : {}}
          >
            {failedStep === step.id ? '✗' : completedSteps.includes(step.id) ? '✓' : step.icon}
          </div>
          {index < STEPS.length - 1 && (
            <div className={`stepper-line ${completedSteps.includes(step.id) ? 'complete' : ''}`} />
          )}
        </div>
      ))}
    </div>
  );
}

// User Selection Component
function UserSelection({ selectedUser, onSelect }) {
  return (
    <div>
      <div className="user-cards">
        {TEST_USERS.filter(u => !u.isAttack).map((user) => (
          <div
            key={user.id}
            className={`user-card ${selectedUser === user.id ? 'selected' : ''}`}
            onClick={() => onSelect(user.id)}
          >
            <div className="avatar">{user.emoji}</div>
            <div className="name">{user.name}</div>
            <div className="description">{user.description}</div>
          </div>
        ))}
      </div>

      <div style={{ marginTop: '32px', padding: '20px', background: 'rgba(239, 68, 68, 0.1)', borderRadius: '16px', border: '1px solid rgba(239, 68, 68, 0.3)' }}>
        <h4 style={{ color: 'var(--color-error)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          ⚠️ Attack Simulation Users
        </h4>
        <p style={{ color: 'var(--color-text-secondary)', fontSize: '14px', marginBottom: '16px' }}>
          Select these users to see how the 5-layer verification catches different attacks:
        </p>
        <div className="user-cards">
          {TEST_USERS.filter(u => u.isAttack).map((user) => (
            <div
              key={user.id}
              className={`user-card ${selectedUser === user.id ? 'selected' : ''}`}
              onClick={() => onSelect(user.id)}
              style={{ borderColor: selectedUser === user.id ? 'var(--color-error)' : 'rgba(239, 68, 68, 0.3)' }}
            >
              <div className="avatar">{user.emoji}</div>
              <div className="name">{user.name}</div>
              <div className="description" style={{ color: 'var(--color-error)' }}>{user.description}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// Step 1: Bank Data Request
function Step1_BankData({ onComplete, selectedUser, setFinancialData, attackType }) {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState(null);

  const fetchData = async () => {
    setLoading(true);

    try {
      const response = await fetch(`${API_URL}/api/financial-data?userId=${selectedUser}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
      });

      if (response.ok) {
        const result = await response.json();
        if (attackType === 'data_tampering') {
          result.tamperedIncome = 200000;
          result.originalIncome = result.income;
          result.income = result.tamperedIncome;
          result.isTampered = true;
        }
        setData(result);
        setFinancialData(result);
      } else {
        throw new Error('API not available');
      }
    } catch (err) {
      const mockData = {
        alice: { income: 120000, debt: 15000, dti: 12.5, creditScore: 85 },
        bob: { income: 35000, debt: 28000, dti: 80, creditScore: 40 },
        charlie: { income: 65000, debt: 20000, dti: 30.7, creditScore: 65 },
        eve: { income: 75000, debt: 10000, dti: 13.3, creditScore: 78 },
        mallory: { income: 45000, debt: 25000, dti: 55.5, creditScore: 52 },
      };

      let userData = mockData[selectedUser] || mockData.alice;
      const signature = '0x' + Array(128).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('');

      if (attackType === 'data_tampering') {
        userData = {
          ...userData,
          originalIncome: userData.income,
          tamperedIncome: 200000,
          income: 200000,
          isTampered: true,
        };
      }

      const result = {
        ...userData,
        signature,
        timestamp: new Date().toISOString(),
        fromMockFallback: true,
      };

      setData(result);
      setFinancialData(result);
    }

    setLoading(false);
  };

  return (
    <div className="glass-card animate-fade-in">
      <div className="step-title">
        <h2>🏦 Step 1: Request Bank Data</h2>
        <p>Fetching your financial data from the bank's HTTPS API</p>
      </div>

      {attackType === 'data_tampering' && (
        <div style={{ background: 'rgba(239, 68, 68, 0.2)', padding: '16px', borderRadius: '8px', marginBottom: '24px', border: '1px solid var(--color-error)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '14px' }}>
            ⚠️ <strong>ATTACK MODE:</strong> Mallory will tamper with the income value after receiving bank data.
          </p>
        </div>
      )}

      {!data ? (
        <div style={{ textAlign: 'center', padding: '32px' }}>
          <button className="btn btn-primary" onClick={fetchData} disabled={loading}>
            {loading ? (
              <><span className="spinner"></span>Connecting to Bank API...</>
            ) : (
              <>📡 Fetch Financial Data</>
            )}
          </button>
        </div>
      ) : (
        <div className="animate-fade-in">
          <div className="data-grid">
            <div className="data-item">
              <label>Annual Income</label>
              <div className={`value ${data.isTampered ? 'error' : 'success'}`}>
                ${data.income.toLocaleString()}
                {data.isTampered && <span style={{ fontSize: '12px', display: 'block', color: 'var(--color-error)' }}>⚠️ TAMPERED</span>}
              </div>
            </div>
            <div className="data-item">
              <label>Total Debt</label>
              <div className="value warning">${data.debt.toLocaleString()}</div>
            </div>
            <div className="data-item">
              <label>Debt-to-Income</label>
              <div className={`value ${data.dti < 30 ? 'success' : 'error'}`}>{data.dti}%</div>
            </div>
            <div className="data-item">
              <label>Credit Score</label>
              <div className={`value ${data.creditScore >= 70 ? 'success' : data.creditScore >= 50 ? 'warning' : 'error'}`}>
                {data.creditScore}
              </div>
            </div>
          </div>

          <button className="btn btn-primary" onClick={onComplete} style={{ marginTop: '24px', width: '100%' }}>
            Continue to zkTLS Proof →
          </button>
        </div>
      )}
    </div>
  );
}

// TLS Handshake Animation Component
function TLSHandshakeVisualization({ currentStep, completedSteps }) {
  return (
    <div style={{
      background: 'var(--color-bg-secondary)',
      borderRadius: '12px',
      padding: '20px',
      marginBottom: '24px'
    }}>
      <h4 style={{ marginBottom: '16px', fontSize: '14px', color: 'var(--color-text-muted)' }}>
        🔐 TLS Handshake Progress
      </h4>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div style={{ textAlign: 'center', width: '80px' }}>
          <div style={{ fontSize: '24px', marginBottom: '4px' }}>💻</div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>Client</div>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px', padding: '0 16px' }}>
          {TLS_HANDSHAKE_STEPS.map((step) => (
            <div
              key={step.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                opacity: completedSteps.includes(step.id) ? 1 : currentStep === step.id ? 1 : 0.3,
                transition: 'all 0.3s ease'
              }}
            >
              <div style={{
                width: '20px',
                height: '20px',
                borderRadius: '50%',
                background: completedSteps.includes(step.id) ? 'var(--color-success)' :
                  currentStep === step.id ? 'var(--color-primary)' : 'var(--color-bg-glass)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '10px',
                color: 'white'
              }}>
                {completedSteps.includes(step.id) ? '✓' : step.id}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{
                  height: '2px',
                  background: step.direction === 'right' ? 'linear-gradient(90deg, var(--color-primary), transparent)' :
                    step.direction === 'left' ? 'linear-gradient(90deg, transparent, var(--color-secondary))' :
                      step.direction === 'proof' ? 'linear-gradient(90deg, var(--color-success), var(--color-success))' :
                        'var(--gradient-primary)',
                  animation: currentStep === step.id ? 'pulse 1s infinite' : 'none'
                }} />
              </div>
              <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', width: '150px' }}>
                {step.name}
              </div>
            </div>
          ))}
        </div>
        <div style={{ textAlign: 'center', width: '80px' }}>
          <div style={{ fontSize: '24px', marginBottom: '4px' }}>🏦</div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>Bank</div>
        </div>
      </div>
    </div>
  );
}

// Trust Level Comparison Component
function TrustLevelComparison({ mode }) {
  const levels = [
    {
      method: 'Traditional Oracle',
      icon: '🔴',
      trust: 20,
      issues: ['Single point of failure', 'Oracle can forge data', 'No cryptographic proof'],
      color: 'var(--color-error)'
    },
    {
      method: 'ECDSA Signature',
      icon: '🟡',
      trust: 60,
      issues: ['Requires trusted signer', 'Bank must cooperate', 'Key management risks'],
      color: 'var(--color-warning)'
    },
    {
      method: 'zkTLS (TLSNotary)',
      icon: '🟢',
      trust: 95,
      issues: ['Proves real TLS session', 'No trusted third party', 'Cryptographic guarantee'],
      color: 'var(--color-success)',
      isActive: mode === 'zktls'
    },
  ];

  return (
    <div style={{
      background: 'var(--color-bg-secondary)',
      borderRadius: '12px',
      padding: '20px',
      border: '1px solid var(--color-border)'
    }}>
      <h4 style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        ⚖️ Trust Level Comparison
      </h4>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {levels.map((level, idx) => (
          <div
            key={idx}
            style={{
              padding: '16px',
              borderRadius: '8px',
              background: level.isActive ? 'rgba(16, 185, 129, 0.15)' : 'var(--color-bg-glass)',
              border: level.isActive ? '2px solid var(--color-success)' : '1px solid var(--color-border)',
              transition: 'all 0.3s ease'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '20px' }}>{level.icon}</span>
                <span style={{ fontWeight: '600' }}>{level.method}</span>
                {level.isActive && <span style={{ fontSize: '12px', background: 'var(--color-success)', color: 'white', padding: '2px 8px', borderRadius: '4px' }}>ACTIVE</span>}
              </div>
              <div style={{ fontSize: '18px', fontWeight: '700', color: level.color }}>{level.trust}%</div>
            </div>
            <div style={{
              height: '6px',
              background: 'var(--color-bg-primary)',
              borderRadius: '3px',
              overflow: 'hidden',
              marginBottom: '8px'
            }}>
              <div style={{
                width: `${level.trust}%`,
                height: '100%',
                background: level.color,
                transition: 'width 0.5s ease'
              }} />
            </div>
            <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
              {level.issues.map((issue, i) => (
                <span key={i}>
                  {level.trust >= 90 ? '✅' : level.trust >= 50 ? '⚠️' : '❌'} {issue}
                  {i < level.issues.length - 1 ? ' • ' : ''}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Session Proof Display Component
function SessionProofDisplay({ proof }) {
  return (
    <div style={{
      background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(99, 102, 241, 0.1))',
      borderRadius: '12px',
      padding: '20px',
      border: '1px solid var(--color-success)',
      marginTop: '24px'
    }}>
      <h4 style={{ marginBottom: '16px', color: 'var(--color-success)', display: 'flex', alignItems: 'center', gap: '8px' }}>
        ✨ TLSNotary Session Proof Generated
      </h4>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
        <div>
          <label style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Session ID</label>
          <div style={{ fontFamily: 'monospace', fontSize: '12px', color: 'var(--color-text-secondary)', wordBreak: 'break-all' }}>
            {proof.sessionId}
          </div>
        </div>
        <div>
          <label style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Notary Signature</label>
          <div style={{ fontFamily: 'monospace', fontSize: '12px', color: 'var(--color-text-secondary)', wordBreak: 'break-all' }}>
            {proof.notarySignature}
          </div>
        </div>
        <div>
          <label style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Server Certificate</label>
          <div style={{ fontFamily: 'monospace', fontSize: '12px', color: 'var(--color-text-secondary)' }}>
            {proof.serverCert}
          </div>
        </div>
        <div>
          <label style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Timestamp</label>
          <div style={{ fontFamily: 'monospace', fontSize: '12px', color: 'var(--color-text-secondary)' }}>
            {proof.timestamp}
          </div>
        </div>
      </div>

      <div style={{ marginTop: '16px', padding: '12px', background: 'rgba(16, 185, 129, 0.2)', borderRadius: '8px' }}>
        <p style={{ fontSize: '13px', color: 'var(--color-success)' }}>
          🔒 <strong>Zero Trust Achieved:</strong> This proof cryptographically verifies that the financial data
          came from a real HTTPS session with the bank, without trusting any oracle or intermediary.
        </p>
      </div>
    </div>
  );
}

// Step 2: zkTLS Certificate Verification
function Step2_zkTLS({ onComplete, financialData, attackType, onAttackFail }) {
  const [mode, setMode] = useState('ecdsa');
  const [handshakeStep, setHandshakeStep] = useState(0);
  const [completedHandshake, setCompletedHandshake] = useState([]);
  const [sessionProof, setSessionProof] = useState(null);
  const [verified, setVerified] = useState(false);
  const [failed, setFailed] = useState(false);

  const runHandshake = async () => {
    for (let i = 1; i <= 5; i++) {
      setHandshakeStep(i);
      await new Promise(r => setTimeout(r, 800));
      setCompletedHandshake(prev => [...prev, i]);
    }

    setSessionProof({
      sessionId: '0x' + Array(32).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      notarySignature: '0x' + Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('').slice(0, 32) + '...',
      serverCert: 'CN=api.bank.com, O=SecureBank Inc.',
      timestamp: new Date().toISOString(),
    });
    setHandshakeStep(0);
  };

  const verify = async () => {
    if (attackType === 'data_tampering' || financialData?.isTampered) {
      setFailed(true);
      onAttackFail(2, 'DATA_TAMPERING', 'Signature does not match the provided data.');
      return;
    }
    setVerified(true);
  };

  return (
    <div className="glass-card animate-fade-in">
      <div className="step-title">
        <h2>🔒 Step 2: zkTLS Data Provenance</h2>
        <p>Proving your financial data came from a real bank connection</p>
      </div>

      {failed ? (
        <div className="animate-fade-in" style={{ textAlign: 'center', padding: '32px' }}>
          <div style={{ fontSize: '80px', marginBottom: '16px' }}>🚨</div>
          <h3 style={{ color: 'var(--color-error)', marginBottom: '8px' }}>Data Tampering Detected!</h3>
          <p style={{ color: 'var(--color-text-secondary)' }}>The data signature doesn't match.</p>
        </div>
      ) : verified ? (
        <div className="animate-fade-in" style={{ textAlign: 'center', padding: '32px' }}>
          <div style={{ fontSize: '80px', marginBottom: '16px' }}>✅</div>
          <h3 style={{ color: 'var(--color-success)', marginBottom: '24px' }}>
            {mode === 'zktls' ? 'zkTLS Proof Verified!' : 'Signature Verified!'}
          </h3>
          <button className="btn btn-primary" onClick={onComplete}>Continue to ML Scoring →</button>
        </div>
      ) : (
        <>
          <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
            <button
              onClick={() => setMode('ecdsa')}
              style={{
                flex: 1,
                padding: '12px',
                borderRadius: '8px',
                border: mode === 'ecdsa' ? '2px solid var(--color-warning)' : '1px solid var(--color-border)',
                background: mode === 'ecdsa' ? 'rgba(245, 158, 11, 0.15)' : 'transparent',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
            >
              <div style={{ fontSize: '20px', marginBottom: '4px' }}>🔏</div>
              <div style={{ fontSize: '14px', fontWeight: '600', color: mode === 'ecdsa' ? 'var(--color-warning)' : 'var(--color-text-primary)' }}>
                ECDSA Signature
              </div>
              <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Current: Trusted Oracle</div>
            </button>
            <button
              onClick={() => setMode('zktls')}
              style={{
                flex: 1,
                padding: '12px',
                borderRadius: '8px',
                border: mode === 'zktls' ? '2px solid var(--color-success)' : '1px solid var(--color-border)',
                background: mode === 'zktls' ? 'rgba(16, 185, 129, 0.15)' : 'transparent',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
            >
              <div style={{ fontSize: '20px', marginBottom: '4px' }}>🔐</div>
              <div style={{ fontSize: '14px', fontWeight: '600', color: mode === 'zktls' ? 'var(--color-success)' : 'var(--color-text-primary)' }}>
                zkTLS (TLSNotary)
              </div>
              <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Future: Zero Trust</div>
            </button>
          </div>

          {mode === 'zktls' && (
            <>
              <TLSHandshakeVisualization currentStep={handshakeStep} completedSteps={completedHandshake} />

              {!sessionProof ? (
                <button
                  className="btn btn-primary"
                  onClick={runHandshake}
                  disabled={handshakeStep > 0}
                  style={{ width: '100%', marginBottom: '24px' }}
                >
                  {handshakeStep > 0 ? `Running TLS Handshake... Step ${handshakeStep}/5` : '🔐 Generate TLS Session Proof'}
                </button>
              ) : (
                <SessionProofDisplay proof={sessionProof} />
              )}
            </>
          )}

          {mode === 'ecdsa' && (
            <div style={{ padding: '20px', background: 'var(--color-bg-secondary)', borderRadius: '12px', marginBottom: '24px' }}>
              <h4 style={{ marginBottom: '12px' }}>🔏 Bank ECDSA Signature</h4>
              <div style={{
                fontFamily: 'monospace',
                fontSize: '11px',
                background: 'var(--color-bg-primary)',
                padding: '12px',
                borderRadius: '8px',
                wordBreak: 'break-all',
                color: 'var(--color-text-secondary)'
              }}>
                {financialData?.signature || '0x...'}
              </div>
            </div>
          )}

          <TrustLevelComparison mode={mode} />

          <button
            className="btn btn-primary"
            onClick={verify}
            disabled={mode === 'zktls' && !sessionProof}
            style={{ width: '100%', marginTop: '24px' }}
          >
            {mode === 'zktls' ? '✅ Verify zkTLS Proof' : '✅ Verify ECDSA Signature'}
          </button>
        </>
      )}
    </div>
  );
}

// Step 3: ML Model Scoring
function Step3_MLScore({ onComplete, financialData, attackType }) {
  const [progress, setProgress] = useState(0);
  const [score, setScore] = useState(null);

  const runModel = () => {
    setProgress(0);
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setScore(financialData?.creditScore || 75);
          return 100;
        }
        return prev + 2;
      });
    }, 50);
  };

  return (
    <div className="glass-card animate-fade-in">
      <div className="step-title">
        <h2>🧠 Step 3: ML Credit Scoring</h2>
        <p>Running the credit scoring model locally on your device</p>
      </div>

      {attackType === 'model_tampering' && (
        <div style={{ background: 'rgba(239, 68, 68, 0.2)', padding: '16px', borderRadius: '8px', marginBottom: '24px', border: '1px solid var(--color-error)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '14px' }}>
            ⚠️ <strong>ATTACK MODE:</strong> Eve is using a MODIFIED ML model!
          </p>
        </div>
      )}

      {score === null ? (
        <div style={{ textAlign: 'center', padding: '32px' }}>
          {progress === 0 ? (
            <>
              <div style={{ fontSize: '64px', marginBottom: '24px' }}>🤖</div>
              <button className="btn btn-primary" onClick={runModel}>🚀 Run Credit Model</button>
            </>
          ) : (
            <>
              <div style={{ fontSize: '48px', marginBottom: '16px' }}>⚙️</div>
              <div className="progress-bar" style={{ maxWidth: '400px', margin: '0 auto' }}>
                <div className="progress-bar-fill" style={{ width: `${progress}%` }} />
              </div>
              <p style={{ marginTop: '12px', color: 'var(--color-primary-light)' }}>{progress}%</p>
            </>
          )}
        </div>
      ) : (
        <div className="score-display animate-fade-in">
          <div className="score-circle" style={{
            borderColor: attackType === 'model_tampering' ? 'var(--color-error)' :
              score >= 70 ? 'var(--color-success)' : score >= 50 ? 'var(--color-warning)' : 'var(--color-error)'
          }}>
            <div className="score">{attackType === 'model_tampering' ? '99' : score}</div>
            <div className="label">Credit Score</div>
          </div>
          <button className="btn btn-primary" onClick={onComplete} style={{ marginTop: '24px' }}>
            Generate ZK Proof →
          </button>
        </div>
      )}
    </div>
  );
}

// Step 4: ZK Proof Generation
function Step4_ZKProof({ onComplete, attackType }) {
  const [generating, setGenerating] = useState(false);
  const [proof, setProof] = useState(null);
  const modelHash = attackType === 'model_tampering' ? TAMPERED_MODEL_HASH : OFFICIAL_MODEL_HASH;

  const generateProof = async () => {
    setGenerating(true);
    await new Promise(r => setTimeout(r, 3000));
    setProof({
      hash: '0x' + Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      modelHash: modelHash,
      isUsingTamperedModel: attackType === 'model_tampering',
    });
    setGenerating(false);
  };

  return (
    <div className="glass-card animate-fade-in">
      <div className="step-title">
        <h2>🔐 Step 4: Generate ZK Proof</h2>
        <p>Creating a zero-knowledge proof of creditworthiness</p>
      </div>

      {!proof ? (
        <div style={{ textAlign: 'center', padding: '32px' }}>
          <div style={{ fontSize: '64px', marginBottom: '24px' }}>{generating ? '⏳' : '🔮'}</div>
          <button className="btn btn-primary" onClick={generateProof} disabled={generating}>
            {generating ? 'Generating Proof...' : '🔐 Generate ZK Proof'}
          </button>
        </div>
      ) : (
        <div className="animate-fade-in">
          <div style={{ textAlign: 'center', marginBottom: '24px' }}>
            <div style={{ fontSize: '64px' }}>✨</div>
            <h3 style={{ color: 'var(--color-success)' }}>Proof Generated!</h3>
          </div>

          <div className="hash-compare">
            <div className="hash-box" style={proof.isUsingTamperedModel ? { borderColor: 'var(--color-error)' } : {}}>
              <label>Proof Model Hash</label>
              <div className="hash" style={proof.isUsingTamperedModel ? { color: 'var(--color-error)' } : {}}>
                {proof.modelHash.slice(0, 20)}...
              </div>
            </div>
            <div className="hash-match" style={{ color: proof.isUsingTamperedModel ? 'var(--color-error)' : 'var(--color-success)' }}>
              {proof.isUsingTamperedModel ? '≠' : '='}
            </div>
            <div className="hash-box">
              <label>On-Chain Model Hash</label>
              <div className="hash">{OFFICIAL_MODEL_HASH.slice(0, 20)}...</div>
            </div>
          </div>

          <button className="btn btn-primary" onClick={onComplete} style={{ marginTop: '24px', width: '100%' }}>
            Submit for Verification →
          </button>
        </div>
      )}
    </div>
  );
}

// Smart Contract Constraint Rules
const CONTRACT_RULES = {
  minIncome: 30000,
  maxDTI: 30,
  minCreditScore: 50,
};

// Constraint Check Component
function ConstraintCheck({ label, value, threshold, operator, unit, isPassing }) {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '12px 16px',
      background: isPassing ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
      borderRadius: '8px',
      border: `1px solid ${isPassing ? 'var(--color-success)' : 'var(--color-error)'}`,
      marginBottom: '8px',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ fontSize: '20px' }}>{isPassing ? '✅' : '❌'}</span>
        <div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>{label}</div>
          <div style={{ fontSize: '16px', fontWeight: '600', color: isPassing ? 'var(--color-success)' : 'var(--color-error)' }}>
            {unit === '$' ? `$${value.toLocaleString()}` : `${value}${unit}`}
          </div>
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>THRESHOLD</div>
        <div style={{ fontSize: '14px', color: 'var(--color-text-secondary)', fontFamily: 'monospace' }}>
          {operator} {unit === '$' ? `$${threshold.toLocaleString()}` : `${threshold}${unit}`}
        </div>
      </div>
    </div>
  );
}

// Step 5: On-Chain Verification
function Step5_Verification({ onComplete, financialData, attackType, onAttackFail }) {
  const [currentLayer, setCurrentLayer] = useState(-1);
  const [verifiedLayers, setVerifiedLayers] = useState([]);
  const [failedLayer, setFailedLayer] = useState(null);
  const [isComplete, setIsComplete] = useState(false);
  const [showConstraints, setShowConstraints] = useState(false);

  const incomePass = (financialData?.income || 0) >= CONTRACT_RULES.minIncome;
  const dtiPass = (financialData?.dti || 100) <= CONTRACT_RULES.maxDTI;
  const scorePass = (financialData?.creditScore || 0) >= CONTRACT_RULES.minCreditScore;
  const allConstraintsPass = incomePass && dtiPass && scorePass;

  const startVerification = () => {
    setCurrentLayer(0);
    let failAtLayer = null;
    if (attackType === 'model_tampering') failAtLayer = 4;
    else if (!allConstraintsPass) failAtLayer = 1;

    LAYERS.forEach((layer, index) => {
      setTimeout(() => {
        if (layer.id === 1) setShowConstraints(true);

        if (failAtLayer === layer.id) {
          setFailedLayer(layer.id);
          setCurrentLayer(-1);
          const reason = layer.id === 1 ? 'Constraint check failed' : 'Model hash mismatch';
          onAttackFail(5, layer.id === 1 ? 'CONSTRAINT_VIOLATION' : 'MODEL_TAMPERING', reason);
          return;
        }

        setVerifiedLayers(prev => [...prev, layer.id]);
        if (index < LAYERS.length - 1) setCurrentLayer(index + 1);
        else {
          setCurrentLayer(-1);
          setIsComplete(true);
        }
      }, (index + 1) * 1200);
    });
  };

  return (
    <div className="glass-card animate-fade-in">
      <div className="step-title">
        <h2>✅ Step 5: On-Chain Verification</h2>
        <p>Smart contract validates your proof through 5 security layers</p>
      </div>

      {currentLayer === -1 && verifiedLayers.length === 0 && !failedLayer ? (
        <div style={{ textAlign: 'center', padding: '32px' }}>
          <div style={{ fontSize: '64px', marginBottom: '24px' }}>⛓️</div>
          <button className="btn btn-primary" onClick={startVerification}>🚀 Start Verification</button>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: showConstraints ? '1fr 1fr' : '1fr', gap: '24px' }}>
          <div className="verification-layers">
            {LAYERS.map((layer) => (
              <div
                key={layer.id}
                className={`layer ${failedLayer === layer.id ? 'failed' : currentLayer === layer.id ? 'verifying' : verifiedLayers.includes(layer.id) ? 'verified' : ''}`}
                style={failedLayer === layer.id ? { borderColor: 'var(--color-error)', background: 'rgba(239, 68, 68, 0.1)' } : {}}
              >
                <div
                  className={`layer-icon ${failedLayer === layer.id ? 'failed' : currentLayer === layer.id ? 'verifying' : verifiedLayers.includes(layer.id) ? 'verified' : 'pending'}`}
                  style={failedLayer === layer.id ? { background: 'var(--color-error)' } : {}}
                >
                  {failedLayer === layer.id ? '✗' : verifiedLayers.includes(layer.id) ? '✓' : currentLayer === layer.id ? '↻' : layer.id}
                </div>
                <div className="layer-info">
                  <h4 style={failedLayer === layer.id ? { color: 'var(--color-error)' } : {}}>
                    Layer {layer.id}: {layer.name} {failedLayer === layer.id && '- FAILED!'}
                  </h4>
                  <p>{layer.desc}</p>
                </div>
              </div>
            ))}

            {isComplete && (
              <div style={{ textAlign: 'center', marginTop: '24px' }}>
                <button className="btn btn-primary" onClick={onComplete}>View Result →</button>
              </div>
            )}
          </div>

          {showConstraints && (
            <div className="animate-fade-in" style={{ background: 'var(--color-bg-secondary)', borderRadius: '16px', padding: '20px' }}>
              <h4 style={{ marginBottom: '16px' }}>📋 Smart Contract Rules</h4>
              <ConstraintCheck label="Minimum Income" value={financialData?.income || 0} threshold={CONTRACT_RULES.minIncome} operator="≥" unit="$" isPassing={incomePass} />
              <ConstraintCheck label="Maximum DTI Ratio" value={financialData?.dti || 0} threshold={CONTRACT_RULES.maxDTI} operator="≤" unit="%" isPassing={dtiPass} />
              <ConstraintCheck label="Minimum Credit Score" value={financialData?.creditScore || 0} threshold={CONTRACT_RULES.minCreditScore} operator="≥" unit="" isPassing={scorePass} />
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// Attack Failed Result
function AttackFailedResult({ attackInfo, onReset }) {
  return (
    <div className="glass-card result-card rejected animate-fade-in">
      <div className="result-icon">🛡️</div>
      <h2 className="result-title">Attack Prevented!</h2>
      <p style={{ color: 'var(--color-text-secondary)', marginBottom: '24px' }}>
        The 5-layer verification system blocked this attack.
      </p>
      <div style={{ background: 'rgba(239, 68, 68, 0.2)', padding: '20px', borderRadius: '12px', marginBottom: '24px', textAlign: 'left' }}>
        <strong style={{ color: 'var(--color-error)' }}>{attackInfo.type}</strong>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: '8px' }}>{attackInfo.reason}</p>
      </div>
      <button className="btn btn-secondary" onClick={onReset}>🔄 Try Another Scenario</button>
    </div>
  );
}

// Final Result Component
function FinalResult({ financialData, onReset }) {
  const approved = financialData?.creditScore >= 50 && financialData?.dti < 50;

  return (
    <div className={`glass-card result-card ${approved ? 'approved' : 'rejected'} animate-fade-in`}>
      <div className="result-icon">{approved ? '🎉' : '❌'}</div>
      <h2 className="result-title">{approved ? 'Loan Approved!' : 'Application Rejected'}</h2>
      <p style={{ color: 'var(--color-text-secondary)', marginBottom: '32px' }}>
        {approved ? 'Your ZK-verified loan has been approved!' : 'Application did not meet requirements.'}
      </p>

      {approved && (
        <div className="data-grid" style={{ marginBottom: '32px' }}>
          <div className="data-item">
            <label>Loan Amount</label>
            <div className="value success">0.5 ETH</div>
          </div>
          <div className="data-item">
            <label>Collateral</label>
            <div className="value">{financialData?.creditScore >= 70 ? '120%' : '140%'}</div>
          </div>
        </div>
      )}

      <button className="btn btn-secondary" onClick={onReset}>🔄 Start New Application</button>
    </div>
  );
}

// Main App Component
function App() {
  const [currentStep, setCurrentStep] = useState(0);
  const [completedSteps, setCompletedSteps] = useState([]);
  const [failedStep, setFailedStep] = useState(null);
  const [selectedUser, setSelectedUser] = useState('alice');
  const [financialData, setFinancialData] = useState(null);
  const [attackFailed, setAttackFailed] = useState(null);

  const selectedUserData = TEST_USERS.find(u => u.id === selectedUser);
  const attackType = selectedUserData?.attackType;

  const completeStep = (stepId) => {
    setCompletedSteps(prev => [...prev, stepId]);
    setCurrentStep(stepId + 1);
  };

  const handleAttackFail = (step, type, reason) => {
    setFailedStep(step);
    setAttackFailed({ step, type, reason });
  };

  const reset = () => {
    setCurrentStep(0);
    setCompletedSteps([]);
    setFailedStep(null);
    setFinancialData(null);
    setAttackFailed(null);
  };

  return (
    <div>
      <Header />
      <div className="container">
        <ProgressStepper currentStep={currentStep} completedSteps={completedSteps} failedStep={failedStep} />

        <div className="step-container">
          {currentStep === 0 && (
            <div className="glass-card animate-fade-in">
              <div className="step-title">
                <h2>👤 Select Test User</h2>
                <p>Choose a user profile to simulate different credit scenarios</p>
              </div>
              <UserSelection selectedUser={selectedUser} onSelect={setSelectedUser} />
              <button className="btn btn-primary" onClick={() => setCurrentStep(1)} style={{ marginTop: '24px', width: '100%' }}>
                Start Loan Application →
              </button>
            </div>
          )}

          {attackFailed ? (
            <AttackFailedResult attackInfo={attackFailed} onReset={reset} />
          ) : (
            <>
              {currentStep === 1 && (
                <Step1_BankData onComplete={() => completeStep(1)} selectedUser={selectedUser} setFinancialData={setFinancialData} attackType={attackType} />
              )}
              {currentStep === 2 && (
                <Step2_zkTLS onComplete={() => completeStep(2)} financialData={financialData} attackType={attackType} onAttackFail={handleAttackFail} />
              )}
              {currentStep === 3 && (
                <Step3_MLScore onComplete={() => completeStep(3)} financialData={financialData} attackType={attackType} />
              )}
              {currentStep === 4 && (
                <Step4_ZKProof onComplete={() => completeStep(4)} attackType={attackType} />
              )}
              {currentStep === 5 && (
                <Step5_Verification onComplete={() => completeStep(5)} financialData={financialData} attackType={attackType} onAttackFail={handleAttackFail} />
              )}
              {currentStep === 6 && (
                <FinalResult financialData={financialData} onReset={reset} />
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
