import React, { useState } from 'react';
import { Shield, Lock, Video, Phone, EyeOff, Key, Sparkles, ArrowRight, Copy, Check, Menu, X, Cpu, RefreshCw, Zap, Download } from 'lucide-react';

export const WebHome: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'join' | 'create'>('join');
  const [inputToken, setInputToken] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  
  // Call Link Generator State
  const [callType, setCallType] = useState<'video' | 'audio'>('video');
  const [requirePin, setRequirePin] = useState(false);
  const [customPin, setCustomPin] = useState('');
  const [generatedLink, setGeneratedLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  // Live E2EE Simulator State
  const [simText, setSimText] = useState('Meet me at 5:00 PM in private room 🔒');
  
  // Mobile Nav Drawer State
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleJoinByToken = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = inputToken.trim();
    if (!trimmed) {
      setErrorMsg('Please enter a valid call link or token');
      return;
    }

    if (trimmed.includes('/c/')) {
      const tokenPart = trimmed.split('/c/')[1];
      window.location.href = `/c/${tokenPart}`;
    } else {
      window.location.href = `/c/${trimmed}`;
    }
  };

  const handleGenerateCallLink = (e: React.FormEvent) => {
    e.preventDefault();
    const randomTok = 'room_' + Math.random().toString(36).substring(2, 10);
    const fullUrl = `${window.location.origin}/c/${randomTok}`;
    setGeneratedLink(fullUrl);
  };

  const handleCopyLink = () => {
    if (!generatedLink) return;
    navigator.clipboard.writeText(generatedLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Mock AES-256 Ciphertext Generator for Live Simulator
  const getCiphertext = (text: string) => {
    if (!text) return '0x000000000000000000000000';
    let hash = '';
    for (let i = 0; i < text.length; i++) {
      const charCode = text.charCodeAt(i) ^ 0x5a;
      hash += charCode.toString(16).padStart(2, '0');
    }
    return `e2ee_aes256_gcm:${hash.padEnd(32, 'f')}`;
  };

  return (
    <div
      className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between"
      style={{
        minHeight: '100vh',
        backgroundColor: '#030712',
        color: '#f8fafc',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
      }}
    >
      {/* Dynamic Ambient Background Orbs */}
      <div style={{ position: 'fixed', top: '-10%', left: '50%', transform: 'translateX(-50%)', width: '600px', height: '600px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(37, 99, 235, 0.15) 0%, rgba(0,0,0,0) 70%)', pointerEvents: 'none', zIndex: 0 }} />

      {/* Navigation Header */}
      <header
        style={{
          borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
          backgroundColor: 'rgba(3, 7, 18, 0.85)',
          backdropFilter: 'blur(16px)',
          position: 'sticky',
          top: 0,
          zIndex: 50,
          padding: '16px 24px',
        }}
      >
        <div
          style={{
            maxWidth: '1152px',
            margin: '0 auto',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          {/* Logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '14px',
                background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.3) 0%, rgba(14, 165, 233, 0.15) 100%)',
                border: '1.5px solid rgba(59, 130, 246, 0.4)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: '0 8px 20px rgba(37, 99, 235, 0.2)',
              }}
            >
              <Shield style={{ color: '#3b82f6', width: '22px', height: '22px' }} />
            </div>
            <div>
              <h1 style={{ fontWeight: 900, fontSize: '20px', color: '#ffffff', letterSpacing: '-0.02em', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
                OurSpace{' '}
                <span
                  style={{
                    fontSize: '11px',
                    padding: '2px 8px',
                    borderRadius: '9999px',
                    backgroundColor: 'rgba(59, 130, 246, 0.15)',
                    border: '1px solid rgba(59, 130, 246, 0.4)',
                    color: '#60a5fa',
                    fontWeight: 800,
                  }}
                >
                  ZERO KNOWLEDGE
                </span>
              </h1>
            </div>
          </div>

          {/* Desktop Nav Links */}
          <div className="hidden md:flex" style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
            <a href="#features" style={{ fontSize: '13px', color: '#94a3b8', textDecoration: 'none', fontWeight: 600 }}>Features</a>
            <a href="#simulator" style={{ fontSize: '13px', color: '#94a3b8', textDecoration: 'none', fontWeight: 600 }}>Live E2EE Demo</a>
            <a href="#specs" style={{ fontSize: '13px', color: '#94a3b8', textDecoration: 'none', fontWeight: 600 }}>Protocol Specs</a>
            <a
              href="https://github.com/Virusboot/OurSpace"
              target="_blank"
              rel="noreferrer"
              style={{ fontSize: '13px', color: '#94a3b8', textDecoration: 'none', fontWeight: 600 }}
            >
              GitHub Source
            </a>
            <button
              onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play & App Store.')}
              style={{
                fontSize: '13px',
                fontWeight: 'bold',
                padding: '10px 20px',
                borderRadius: '12px',
                backgroundColor: '#2563eb',
                color: '#ffffff',
                border: 'none',
                cursor: 'pointer',
                boxShadow: '0 8px 20px rgba(37, 99, 235, 0.3)',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <Download style={{ width: '15px', height: '15px' }} />
              <span>Get Mobile App</span>
            </button>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            style={{
              display: 'flex',
              background: 'none',
              border: '1px solid rgba(255,255,255,0.1)',
              padding: '8px',
              borderRadius: '10px',
              color: '#ffffff',
              cursor: 'pointer',
            }}
          >
            {mobileMenuOpen ? <X style={{ width: '20px', height: '20px' }} /> : <Menu style={{ width: '20px', height: '20px' }} />}
          </button>
        </div>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div
            style={{
              padding: '16px 24px 24px',
              borderTop: '1px solid rgba(255,255,255,0.08)',
              display: 'flex',
              flexDirection: 'column',
              gap: '16px',
              backgroundColor: '#030712',
            }}
          >
            <a href="#features" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '14px', color: '#94a3b8', textDecoration: 'none' }}>Features</a>
            <a href="#simulator" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '14px', color: '#94a3b8', textDecoration: 'none' }}>Live E2EE Demo</a>
            <a href="#specs" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '14px', color: '#94a3b8', textDecoration: 'none' }}>Protocol Specs</a>
            <a href="https://github.com/Virusboot/OurSpace" target="_blank" rel="noreferrer" style={{ fontSize: '14px', color: '#94a3b8', textDecoration: 'none' }}>GitHub Repository</a>
            <button
              onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play & App Store.')}
              style={{
                fontSize: '14px',
                fontWeight: 'bold',
                padding: '12px',
                borderRadius: '12px',
                backgroundColor: '#2563eb',
                color: '#ffffff',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              Get Mobile App
            </button>
          </div>
        )}
      </header>

      {/* Main Hero Container */}
      <main style={{ maxWidth: '1152px', margin: '0 auto', padding: '48px 24px', flex: 1, zIndex: 1 }}>
        
        {/* Section 1: Hero Banner & Tagline */}
        <section style={{ textAlign: 'center', marginBottom: '64px' }}>
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '6px 16px',
              borderRadius: '9999px',
              backgroundColor: 'rgba(59, 130, 246, 0.12)',
              border: '1px solid rgba(59, 130, 246, 0.3)',
              color: '#60a5fa',
              fontSize: '12px',
              fontWeight: 800,
              letterSpacing: '0.05em',
              textTransform: 'uppercase',
              marginBottom: '24px',
            }}
          >
            <Sparkles style={{ width: '14px', height: '14px' }} />
            <span>Military-Grade Peer-to-Peer Encryption</span>
          </div>

          <h2
            style={{
              fontSize: 'clamp(32px, 5vw, 56px)',
              fontWeight: 900,
              color: '#ffffff',
              marginBottom: '20px',
              lineHeight: 1.15,
              letterSpacing: '-0.03em',
            }}
          >
            Ultra-Private Calls & <br />
            <span style={{ background: 'linear-gradient(135deg, #60a5fa 0%, #38bdf8 50%, #818cf8 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              Encrypted Communications
            </span>
          </h2>

          <p style={{ color: '#94a3b8', fontSize: '17px', maxWidth: '680px', margin: '0 auto 36px', lineHeight: 1.6 }}>
            Join WebRTC video & voice calls with zero registration, zero phone numbers, and zero server logging. Cryptographic privacy engineered for everyone.
          </p>

          {/* Tab Selector & Interactive Call Hub Card */}
          <div
            style={{
              maxWidth: '520px',
              margin: '0 auto',
              backgroundColor: 'rgba(15, 23, 42, 0.85)',
              backdropFilter: 'blur(20px)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              borderRadius: '24px',
              padding: '24px',
              boxShadow: '0 30px 60px -15px rgba(0, 0, 0, 0.7)',
            }}
          >
            {/* Tabs */}
            <div style={{ display: 'flex', backgroundColor: '#020617', padding: '4px', borderRadius: '14px', marginBottom: '20px', border: '1px solid rgba(255,255,255,0.06)' }}>
              <button
                onClick={() => setActiveTab('join')}
                style={{
                  flex: 1,
                  padding: '10px',
                  borderRadius: '10px',
                  border: 'none',
                  fontSize: '13px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  backgroundColor: activeTab === 'join' ? '#2563eb' : 'transparent',
                  color: activeTab === 'join' ? '#ffffff' : '#94a3b8',
                  transition: 'all 0.2s ease',
                }}
              >
                Join Call Room
              </button>
              <button
                onClick={() => setActiveTab('create')}
                style={{
                  flex: 1,
                  padding: '10px',
                  borderRadius: '10px',
                  border: 'none',
                  fontSize: '13px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  backgroundColor: activeTab === 'create' ? '#2563eb' : 'transparent',
                  color: activeTab === 'create' ? '#ffffff' : '#94a3b8',
                  transition: 'all 0.2s ease',
                }}
              >
                Create Instant Link
              </button>
            </div>

            {/* TAB 1: JOIN CALL ROOM */}
            {activeTab === 'join' && (
              <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', textTransform: 'uppercase' }}>Call Token or Link</span>
                  <span style={{ fontSize: '11px', color: '#60a5fa', fontFamily: 'monospace' }}>WebRTC P2P</span>
                </div>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <input
                    type="text"
                    value={inputToken}
                    onChange={(e) => {
                      setInputToken(e.target.value);
                      setErrorMsg('');
                    }}
                    placeholder="Paste link e.g. /c/room_xyz123"
                    style={{
                      flex: 1,
                      backgroundColor: '#020617',
                      border: '1px solid #334155',
                      borderRadius: '12px',
                      padding: '12px 14px',
                      fontSize: '14px',
                      color: '#ffffff',
                      outline: 'none',
                    }}
                  />
                  <button
                    type="submit"
                    style={{
                      backgroundColor: '#2563eb',
                      color: '#ffffff',
                      fontWeight: 'bold',
                      fontSize: '13px',
                      padding: '0 20px',
                      borderRadius: '12px',
                      border: 'none',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <span>Join</span>
                    <ArrowRight style={{ width: '14px', height: '14px' }} />
                  </button>
                </div>
                {errorMsg && <p style={{ color: '#f43f5e', fontSize: '12px', textAlign: 'left', margin: 0 }}>{errorMsg}</p>}
              </form>
            )}

            {/* TAB 2: CREATE CALL LINK */}
            {activeTab === 'create' && (
              <form onSubmit={handleGenerateCallLink} style={{ display: 'flex', flexDirection: 'column', gap: '14px', textAlign: 'left' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1', textTransform: 'uppercase', display: 'block', marginBottom: '8px' }}>Call Type</label>
                  <div style={{ display: 'flex', gap: '12px' }}>
                    <button
                      type="button"
                      onClick={() => setCallType('video')}
                      style={{
                        flex: 1,
                        padding: '10px',
                        borderRadius: '10px',
                        border: callType === 'video' ? '1.5px solid #2563eb' : '1px solid #334155',
                        backgroundColor: callType === 'video' ? 'rgba(37, 99, 235, 0.2)' : '#020617',
                        color: '#ffffff',
                        fontSize: '13px',
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '6px',
                      }}
                    >
                      <Video style={{ width: '16px', height: '16px', color: '#60a5fa' }} />
                      <span>HD Video Call</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setCallType('audio')}
                      style={{
                        flex: 1,
                        padding: '10px',
                        borderRadius: '10px',
                        border: callType === 'audio' ? '1.5px solid #2563eb' : '1px solid #334155',
                        backgroundColor: callType === 'audio' ? 'rgba(37, 99, 235, 0.2)' : '#020617',
                        color: '#ffffff',
                        fontSize: '13px',
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '6px',
                      }}
                    >
                      <Phone style={{ width: '16px', height: '16px', color: '#60a5fa' }} />
                      <span>Audio Only</span>
                    </button>
                  </div>
                </div>

                <button
                  type="submit"
                  style={{
                    backgroundColor: '#2563eb',
                    color: '#ffffff',
                    fontWeight: 'bold',
                    fontSize: '14px',
                    padding: '12px',
                    borderRadius: '12px',
                    border: 'none',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '8px',
                    marginTop: '4px',
                  }}
                >
                  <Zap style={{ width: '16px', height: '16px' }} />
                  <span>Generate Encrypted Room Link</span>
                </button>

                {generatedLink && (
                  <div style={{ backgroundColor: '#020617', border: '1px solid #334155', borderRadius: '12px', padding: '12px', marginTop: '4px' }}>
                    <span style={{ fontSize: '11px', color: '#94a3b8', display: 'block', marginBottom: '6px', fontWeight: 'bold' }}>YOUR SECURE LINK:</span>
                    <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                      <input
                        type="text"
                        readOnly
                        value={generatedLink}
                        style={{ flex: 1, backgroundColor: 'transparent', border: 'none', color: '#60a5fa', fontSize: '12px', fontFamily: 'monospace', outline: 'none' }}
                      />
                      <button
                        type="button"
                        onClick={handleCopyLink}
                        style={{ backgroundColor: '#1e293b', border: 'none', padding: '6px 12px', borderRadius: '8px', color: '#ffffff', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
                      >
                        {copied ? <Check style={{ width: '14px', height: '14px', color: '#10b981' }} /> : <Copy style={{ width: '14px', height: '14px' }} />}
                        <span>{copied ? 'Copied' : 'Copy'}</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => { window.location.href = generatedLink; }}
                        style={{ backgroundColor: '#10b981', border: 'none', padding: '6px 12px', borderRadius: '8px', color: '#ffffff', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
                      >
                        Enter
                      </button>
                    </div>
                  </div>
                )}
              </form>
            )}
          </div>
        </section>

        {/* Section 2: Live Interactive E2EE Simulator */}
        <section id="simulator" style={{ marginBottom: '80px' }}>
          <div style={{ textTransform: 'uppercase', fontSize: '12px', fontWeight: 800, color: '#60a5fa', letterSpacing: '0.1em', textAlign: 'center', marginBottom: '8px' }}>
            Interactive Demo
          </div>
          <h3 style={{ fontSize: '28px', fontWeight: 900, color: '#ffffff', textAlign: 'center', marginBottom: '24px' }}>
            Real-Time Encryption Engine Simulator
          </h3>

          <div
            style={{
              backgroundColor: '#0f172a',
              border: '1px solid #1e293b',
              borderRadius: '24px',
              padding: '28px',
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: '24px',
            }}
          >
            {/* Plaintext Input */}
            <div style={{ textAlign: 'left' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1' }}>Plaintext Message</label>
                <span style={{ fontSize: '11px', color: '#10b981', fontWeight: 'bold' }}>Device Memory (Client)</span>
              </div>
              <textarea
                value={simText}
                onChange={(e) => setSimText(e.target.value)}
                rows={4}
                style={{
                  width: '100%',
                  backgroundColor: '#020617',
                  border: '1px solid #334155',
                  borderRadius: '14px',
                  padding: '12px 14px',
                  color: '#ffffff',
                  fontSize: '13px',
                  outline: 'none',
                  resize: 'none',
                  boxSizing: 'border-box',
                }}
              />
            </div>

            {/* Ciphertext Output */}
            <div style={{ textAlign: 'left' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <label style={{ fontSize: '12px', fontWeight: 'bold', color: '#cbd5e1' }}>AES-256-GCM Ciphertext Payload</label>
                <span style={{ fontSize: '11px', color: '#60a5fa', fontFamily: 'monospace' }}>Network Relay Wire</span>
              </div>
              <div
                style={{
                  width: '100%',
                  backgroundColor: '#020617',
                  border: '1px solid #1e293b',
                  borderRadius: '14px',
                  padding: '12px 14px',
                  minHeight: '102px',
                  color: '#60a5fa',
                  fontSize: '12px',
                  fontFamily: 'monospace',
                  wordBreak: 'break-all',
                  boxSizing: 'border-box',
                }}
              >
                {getCiphertext(simText)}
              </div>
            </div>
          </div>
        </section>

        {/* Section 3: Feature Grid Cards */}
        <section id="features" style={{ marginBottom: '80px' }}>
          <div style={{ textTransform: 'uppercase', fontSize: '12px', fontWeight: 800, color: '#60a5fa', letterSpacing: '0.1em', textAlign: 'center', marginBottom: '8px' }}>
            Zero-Trust Architecture
          </div>
          <h3 style={{ fontSize: '28px', fontWeight: 900, color: '#ffffff', textAlign: 'center', marginBottom: '32px' }}>
            Built for Absolute Privacy & Security
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '20px', textAlign: 'left' }}>
            <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.7)', border: '1px solid #1e293b', padding: '24px', borderRadius: '20px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '12px', backgroundColor: 'rgba(59, 130, 246, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#60a5fa', marginBottom: '16px' }}>
                <Lock style={{ width: '20px', height: '20px' }} />
              </div>
              <h4 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '16px', marginBottom: '6px' }}>AES-256-GCM + ECDH</h4>
              <p style={{ fontSize: '13px', color: '#94a3b8', lineHeight: 1.6, margin: 0 }}>
                Every message, media payload, and voice packet is encrypted on device using Elliptic-Curve Diffie-Hellman key agreement.
              </p>
            </div>

            <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.7)', border: '1px solid #1e293b', padding: '24px', borderRadius: '20px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '12px', backgroundColor: 'rgba(16, 185, 129, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#34d399', marginBottom: '16px' }}>
                <EyeOff style={{ width: '20px', height: '20px' }} />
              </div>
              <h4 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '16px', marginBottom: '6px' }}>Ghost Mode Disappearing</h4>
              <p style={{ fontSize: '13px', color: '#94a3b8', lineHeight: 1.6, margin: 0 }}>
                Enforces 30s auto-destructing messages, view-once media items, hidden notification previews, and screenshot block.
              </p>
            </div>

            <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.7)', border: '1px solid #1e293b', padding: '24px', borderRadius: '20px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '12px', backgroundColor: 'rgba(99, 102, 241, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#818cf8', marginBottom: '16px' }}>
                <Video style={{ width: '20px', height: '20px' }} />
              </div>
              <h4 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '16px', marginBottom: '6px' }}>WebRTC P2P Media</h4>
              <p style={{ fontSize: '13px', color: '#94a3b8', lineHeight: 1.6, margin: 0 }}>
                Direct peer-to-peer audio and video streaming. Zero server relay storage or interception.
              </p>
            </div>
          </div>
        </section>

        {/* Section 4: Technical Protocol Specs */}
        <section id="specs" style={{ marginBottom: '64px' }}>
          <div style={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '24px', padding: '32px', textAlign: 'left' }}>
            <h3 style={{ fontSize: '20px', fontWeight: 900, color: '#ffffff', marginBottom: '20px' }}>Cryptographic Protocol Audit Specs</h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
              <div>
                <span style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 'bold' }}>Symmetric Cipher</span>
                <p style={{ color: '#60a5fa', fontWeight: 'bold', fontSize: '14px', margin: '2px 0 0' }}>AES-256-GCM (Authenticated)</p>
              </div>
              <div>
                <span style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 'bold' }}>Asymmetric Key Exchange</span>
                <p style={{ color: '#60a5fa', fontWeight: 'bold', fontSize: '14px', margin: '2px 0 0' }}>ECDH (Curve25519)</p>
              </div>
              <div>
                <span style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 'bold' }}>Key Derivation</span>
                <p style={{ color: '#60a5fa', fontWeight: 'bold', fontSize: '14px', margin: '2px 0 0' }}>HKDF-SHA256</p>
              </div>
              <div>
                <span style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 'bold' }}>P2P Call Relay</span>
                <p style={{ color: '#60a5fa', fontWeight: 'bold', fontSize: '14px', margin: '2px 0 0' }}>WebRTC STUN/TURN Direct</p>
              </div>
            </div>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer style={{ borderTop: '1px solid rgba(255, 255, 255, 0.08)', padding: '24px', textAlign: 'center', fontSize: '13px', color: '#64748b', zIndex: 1 }}>
        <div style={{ maxWidth: '1152px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
          <p style={{ margin: 0 }}>© 2026 OurSpace Privacy Chat. All rights reserved.</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <span style={{ color: '#60a5fa', fontWeight: 600 }}>Zero-Knowledge E2EE</span>
            <span>•</span>
            <span style={{ color: '#94a3b8' }}>Open Source</span>
          </div>
        </div>
      </footer>
    </div>
  );
};
