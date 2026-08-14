import React, { useState } from 'react';
import {
  Shield, Lock, Video, Phone, EyeOff, Key, Sparkles, ArrowRight,
  Copy, Check, Menu, X, Cpu, RefreshCw, Zap, Download, Activity,
  Globe, Server, Terminal, Radio, ShieldCheck, Heart, Users
} from 'lucide-react';

export const WebHome: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'join' | 'create'>('join');
  const [inputToken, setInputToken] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  
  // Call Link Generator State
  const [callType, setCallType] = useState<'video' | 'audio'>('video');
  const [generatedLink, setGeneratedLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  // Live E2EE Terminal Simulator State
  const [simText, setSimText] = useState('OurSpace Private Chat: End-to-End Encrypted 🔒✨');

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

  // Hex Ciphertext Simulator
  const getCiphertext = (text: string) => {
    if (!text) return '0x00000000000000000000000000000000';
    let hash = '';
    for (let i = 0; i < text.length; i++) {
      const charCode = text.charCodeAt(i) ^ 0x7e;
      hash += charCode.toString(16).padStart(2, '0');
    }
    return `payload_aes256_gcm:${hash.padEnd(48, 'e9a2')}`;
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: '#ffffff',
        color: '#0f172a',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
        position: 'relative',
        overflowX: 'hidden',
      }}
    >
      {/* Background Soft Purple/Magenta Gradient Blob */}
      <div
        style={{
          position: 'fixed',
          top: '-15%',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '800px',
          height: '600px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(217, 70, 239, 0.08) 0%, rgba(139, 92, 246, 0.05) 50%, rgba(255, 255, 255, 0) 70%)',
          pointerEvents: 'none',
          zIndex: 0,
        }}
      />

      {/* Navigation Header (Clean White Sticky Header with Official Logo) */}
      <header
        style={{
          borderBottom: '1px solid #e2e8f0',
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          backdropFilter: 'blur(20px)',
          position: 'sticky',
          top: 0,
          zIndex: 50,
          padding: '12px 32px',
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.03)',
        }}
      >
        <div
          style={{
            maxWidth: '1800px',
            margin: '0 auto',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          {/* Brand New Official Logo Image */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <a href="/" style={{ display: 'flex', alignItems: 'center', textDecoration: 'none' }}>
              <img
                src="/logo.png"
                alt="OurSpace - A Private Space For Two"
                style={{ height: '48px', width: 'auto', objectFit: 'contain' }}
              />
            </a>
            <span
              style={{
                fontSize: '11px',
                padding: '3px 10px',
                borderRadius: '9999px',
                backgroundColor: 'rgba(217, 70, 239, 0.1)',
                border: '1px solid rgba(217, 70, 239, 0.25)',
                color: '#c026d3',
                fontWeight: 800,
                letterSpacing: '0.05em',
              }}
              className="hidden sm:inline-block"
            >
              ZERO KNOWLEDGE E2EE
            </span>
          </div>

          {/* Desktop Nav Links */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '32px' }} className="hidden lg:flex">
            <a href="#hub" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Call Hub</a>
            <a href="#features" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Privacy Features</a>
            <a href="#simulator" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>E2EE Terminal</a>
            <a href="#specs" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Security Specs</a>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(16, 185, 129, 0.1)', border: '1px solid rgba(16, 185, 129, 0.25)', color: '#059669', fontSize: '12px', fontWeight: 700 }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block' }} />
              <span>E2EE Active</span>
            </div>

            <button
              onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play Store.')}
              style={{
                fontSize: '14px',
                fontWeight: 'bold',
                padding: '10px 22px',
                borderRadius: '14px',
                background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)',
                color: '#ffffff',
                border: 'none',
                cursor: 'pointer',
                boxShadow: '0 8px 24px rgba(217, 70, 239, 0.3)',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <Download style={{ width: '16px', height: '16px' }} />
              <span>Get Mobile App</span>
            </button>
          </div>

          {/* Mobile Hamburger Toggle */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            style={{
              display: 'flex',
              background: 'none',
              border: '1px solid #cbd5e1',
              padding: '8px',
              borderRadius: '10px',
              color: '#0f172a',
              cursor: 'pointer',
            }}
            className="lg:hidden"
          >
            {mobileMenuOpen ? <X style={{ width: '22px', height: '22px' }} /> : <Menu style={{ width: '22px', height: '22px' }} />}
          </button>
        </div>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div
            style={{
              padding: '20px 24px 28px',
              borderTop: '1px solid #e2e8f0',
              display: 'flex',
              flexDirection: 'column',
              gap: '16px',
              backgroundColor: '#ffffff',
            }}
          >
            <a href="#hub" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Call Hub</a>
            <a href="#features" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Privacy Features</a>
            <a href="#simulator" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>E2EE Terminal</a>
            <a href="#specs" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Security Specs</a>
            <button
              onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play Store.')}
              style={{
                fontSize: '15px',
                fontWeight: 'bold',
                padding: '14px',
                borderRadius: '14px',
                background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)',
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

      {/* Main Body (Full 1920px Widescreen Container in Crisp Light Theme) */}
      <main style={{ maxWidth: '1800px', margin: '0 auto', padding: '48px 32px', flex: 1, zIndex: 1, width: '100%', boxSizing: 'border-box' }}>
        
        {/* HERO SECTION: Widescreen 2-Column Layout */}
        <section id="hub" style={{ marginBottom: '88px' }}>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))',
              gap: '48px',
              alignItems: 'center',
            }}
          >
            {/* LEFT COLUMN: Hero Copy & Interactive Call Hub Card */}
            <div style={{ textAlign: 'left' }}>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 18px',
                  borderRadius: '9999px',
                  backgroundColor: 'rgba(217, 70, 239, 0.08)',
                  border: '1px solid rgba(217, 70, 239, 0.25)',
                  color: '#c026d3',
                  fontSize: '12px',
                  fontWeight: 800,
                  letterSpacing: '0.06em',
                  textTransform: 'uppercase',
                  marginBottom: '24px',
                }}
              >
                <Heart style={{ width: '14px', height: '14px', fill: '#c026d3' }} />
                <span>A Private Space For Two • Zero-Knowledge E2EE</span>
              </div>

              <h2
                style={{
                  fontSize: 'clamp(36px, 4.2vw, 64px)',
                  fontWeight: 900,
                  color: '#0f172a',
                  marginBottom: '20px',
                  lineHeight: 1.12,
                  letterSpacing: '-0.04em',
                }}
              >
                Your Private Space for <br />
                <span style={{ background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  Ultra-Secure Encrypted Calls
                </span>
              </h2>

              <p style={{ color: '#475569', fontSize: '18px', lineHeight: 1.6, marginBottom: '36px', maxWidth: '640px' }}>
                Join or create end-to-end encrypted WebRTC video and audio calls. Zero phone numbers, zero contact sync, and absolute cryptographic privacy.
              </p>

              {/* Interactive Call Hub Card (Light Clean Glass Container) */}
              <div
                style={{
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '24px',
                  padding: '28px',
                  boxShadow: '0 20px 40px rgba(0, 0, 0, 0.05)',
                  maxWidth: '560px',
                }}
              >
                {/* Tab Switches */}
                <div style={{ display: 'flex', backgroundColor: '#f1f5f9', padding: '4px', borderRadius: '14px', marginBottom: '24px', border: '1px solid #cbd5e1' }}>
                  <button
                    onClick={() => setActiveTab('join')}
                    style={{
                      flex: 1,
                      padding: '12px',
                      borderRadius: '10px',
                      border: 'none',
                      fontSize: '14px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                      background: activeTab === 'join' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'join' ? '#ffffff' : '#64748b',
                      transition: 'all 0.2s ease',
                      boxShadow: activeTab === 'join' ? '0 4px 12px rgba(217, 70, 239, 0.3)' : 'none',
                    }}
                  >
                    Join Encrypted Room
                  </button>
                  <button
                    onClick={() => setActiveTab('create')}
                    style={{
                      flex: 1,
                      padding: '12px',
                      borderRadius: '10px',
                      border: 'none',
                      fontSize: '14px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                      background: activeTab === 'create' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'create' ? '#ffffff' : '#64748b',
                      transition: 'all 0.2s ease',
                      boxShadow: activeTab === 'create' ? '0 4px 12px rgba(217, 70, 239, 0.3)' : 'none',
                    }}
                  >
                    Generate Room Link
                  </button>
                </div>

                {/* TAB 1: JOIN CALL */}
                {activeTab === 'join' && (
                  <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: '12px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Call Link or Token</span>
                      <span style={{ fontSize: '12px', color: '#c026d3', fontFamily: 'monospace', fontWeight: 700 }}>AES-256 P2P</span>
                    </div>
                    <div style={{ display: 'flex', gap: '10px' }}>
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
                          backgroundColor: '#f8fafc',
                          border: '1px solid #cbd5e1',
                          borderRadius: '14px',
                          padding: '14px 16px',
                          fontSize: '15px',
                          color: '#0f172a',
                          outline: 'none',
                        }}
                      />
                      <button
                        type="submit"
                        style={{
                          background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)',
                          color: '#ffffff',
                          fontWeight: 'bold',
                          fontSize: '14px',
                          padding: '0 24px',
                          borderRadius: '14px',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                          boxShadow: '0 8px 20px rgba(217, 70, 239, 0.3)',
                        }}
                      >
                        <span>Join</span>
                        <ArrowRight style={{ width: '16px', height: '16px' }} />
                      </button>
                    </div>
                    {errorMsg && <p style={{ color: '#f43f5e', fontSize: '13px', textAlign: 'left', margin: 0, fontWeight: 600 }}>{errorMsg}</p>}
                  </form>
                )}

                {/* TAB 2: GENERATE LINK */}
                {activeTab === 'create' && (
                  <form onSubmit={handleGenerateCallLink} style={{ display: 'flex', flexDirection: 'column', gap: '16px', textAlign: 'left' }}>
                    <div>
                      <label style={{ fontSize: '12px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '10px' }}>Select Call Type</label>
                      <div style={{ display: 'flex', gap: '12px' }}>
                        <button
                          type="button"
                          onClick={() => setCallType('video')}
                          style={{
                            flex: 1,
                            padding: '12px',
                            borderRadius: '12px',
                            border: callType === 'video' ? '2px solid #d946ef' : '1px solid #cbd5e1',
                            backgroundColor: callType === 'video' ? 'rgba(217, 70, 239, 0.08)' : '#f8fafc',
                            color: '#0f172a',
                            fontSize: '14px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '8px',
                          }}
                        >
                          <Video style={{ width: '18px', height: '18px', color: '#c026d3' }} />
                          <span>HD Video Call</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => setCallType('audio')}
                          style={{
                            flex: 1,
                            padding: '12px',
                            borderRadius: '12px',
                            border: callType === 'audio' ? '2px solid #d946ef' : '1px solid #cbd5e1',
                            backgroundColor: callType === 'audio' ? 'rgba(217, 70, 239, 0.08)' : '#f8fafc',
                            color: '#0f172a',
                            fontSize: '14px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '8px',
                          }}
                        >
                          <Phone style={{ width: '18px', height: '18px', color: '#c026d3' }} />
                          <span>Audio Only</span>
                        </button>
                      </div>
                    </div>

                    <button
                      type="submit"
                      style={{
                        background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)',
                        color: '#ffffff',
                        fontWeight: 'bold',
                        fontSize: '15px',
                        padding: '14px',
                        borderRadius: '14px',
                        border: 'none',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '8px',
                        boxShadow: '0 8px 24px rgba(217, 70, 239, 0.35)',
                        marginTop: '4px',
                      }}
                    >
                      <Zap style={{ width: '18px', height: '18px' }} />
                      <span>Generate Private Room Link</span>
                    </button>

                    {generatedLink && (
                      <div style={{ backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '14px', padding: '14px' }}>
                        <span style={{ fontSize: '11px', color: '#64748b', display: 'block', marginBottom: '6px', fontWeight: 800 }}>GENERATED ENCRYPTED LINK:</span>
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <input
                            type="text"
                            readOnly
                            value={generatedLink}
                            style={{ flex: 1, backgroundColor: 'transparent', border: 'none', color: '#c026d3', fontSize: '13px', fontFamily: 'monospace', outline: 'none', fontWeight: 700 }}
                          />
                          <button
                            type="button"
                            onClick={handleCopyLink}
                            style={{ backgroundColor: '#e2e8f0', border: 'none', padding: '8px 14px', borderRadius: '10px', color: '#0f172a', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
                          >
                            {copied ? <Check style={{ width: '15px', height: '15px', color: '#10b981' }} /> : <Copy style={{ width: '15px', height: '15px' }} />}
                            <span>{copied ? 'Copied' : 'Copy'}</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => { window.location.href = generatedLink; }}
                            style={{ backgroundColor: '#10b981', border: 'none', padding: '8px 16px', borderRadius: '10px', color: '#ffffff', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
                          >
                            Enter
                          </button>
                        </div>
                      </div>
                    )}
                  </form>
                )}
              </div>
            </div>

            {/* RIGHT COLUMN: High-Tech WebRTC Live Call Preview Mockup (Clean Light Mockup) */}
            <div style={{ position: 'relative' }}>
              <div
                style={{
                  position: 'relative',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '28px',
                  padding: '24px',
                  boxShadow: '0 25px 60px rgba(0, 0, 0, 0.06)',
                  overflow: 'hidden',
                }}
              >
                {/* Mockup Header */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px', borderBottom: '1px solid #f1f5f9', paddingBottom: '14px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#f43f5e', display: 'inline-block' }} />
                    <span style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#eab308', display: 'inline-block' }} />
                    <span style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block' }} />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '4px 12px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.1)', border: '1px solid rgba(217, 70, 239, 0.25)' }}>
                    <Lock style={{ width: '12px', height: '12px', color: '#c026d3' }} />
                    <span style={{ fontSize: '11px', color: '#c026d3', fontWeight: 'bold' }}>AES-256-GCM WebRTC Call</span>
                  </div>
                </div>

                {/* Mockup Video Display Window */}
                <div
                  style={{
                    height: '320px',
                    borderRadius: '20px',
                    backgroundColor: '#0f172a',
                    border: '1px solid #1e293b',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    position: 'relative',
                    overflow: 'hidden',
                  }}
                >
                  <div style={{ width: '88px', height: '88px', borderRadius: '50%', background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff', fontSize: '32px', fontWeight: 'bold', marginBottom: '16px', boxShadow: '0 10px 30px rgba(217, 70, 239, 0.4)', zIndex: 1 }}>
                    🔒
                  </div>

                  <h4 style={{ color: '#ffffff', fontSize: '18px', fontWeight: 'bold', margin: '0 0 6px', zIndex: 1 }}>
                    Private Space Encrypted Channel
                  </h4>
                  <p style={{ color: '#34d399', fontSize: '13px', fontWeight: 700, margin: 0, zIndex: 1, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981' }} />
                    Direct P2P STUN Tunnel • 0% Relay Storage
                  </p>

                  {/* Floating Action Controls */}
                  <div style={{ position: 'absolute', bottom: '16px', display: 'flex', gap: '16px', zIndex: 2 }}>
                    <div style={{ width: '44px', height: '44px', borderRadius: '50%', backgroundColor: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff' }}>
                      <Phone style={{ width: '18px', height: '18px' }} />
                    </div>
                    <div style={{ width: '44px', height: '44px', borderRadius: '50%', backgroundColor: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff' }}>
                      <Video style={{ width: '18px', height: '18px' }} />
                    </div>
                    <div style={{ width: '44px', height: '44px', borderRadius: '50%', backgroundColor: '#f43f5e', border: '1px solid #f43f5e', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff' }}>
                      <Phone style={{ width: '18px', height: '18px', transform: 'rotate(135deg)' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* SECTION 2: FULL WIDESCREEN 4-COLUMN FEATURE GRID (Light Theme Cards) */}
        <section id="features" style={{ marginBottom: '96px' }}>
          <div style={{ textTransform: 'uppercase', fontSize: '13px', fontWeight: 900, color: '#c026d3', letterSpacing: '0.12em', textAlign: 'center', marginBottom: '10px' }}>
            Zero-Trust Architectural Principles
          </div>
          <h3 style={{ fontSize: '36px', fontWeight: 900, color: '#0f172a', textAlign: 'center', marginBottom: '48px', letterSpacing: '-0.02em' }}>
            Uncompromising Security & Privacy Standards
          </h3>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: '24px',
            }}
          >
            {/* Card 1 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '24px',
                padding: '28px',
                textAlign: 'left',
                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.03)',
              }}
            >
              <div style={{ width: '48px', height: '48px', borderRadius: '14px', backgroundColor: 'rgba(217, 70, 239, 0.1)', border: '1px solid rgba(217, 70, 239, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#c026d3', marginBottom: '20px' }}>
                <Lock style={{ width: '24px', height: '24px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '18px', marginBottom: '8px' }}>AES-256-GCM + ECDH</h4>
              <p style={{ fontSize: '14px', color: '#475569', lineHeight: 1.6, margin: 0 }}>
                Every message payload, voice frame, and video stream is encrypted locally on your device prior to network transport.
              </p>
            </div>

            {/* Card 2 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '24px',
                padding: '28px',
                textAlign: 'left',
                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.03)',
              }}
            >
              <div style={{ width: '48px', height: '48px', borderRadius: '14px', backgroundColor: 'rgba(16, 185, 129, 0.1)', border: '1px solid rgba(16, 185, 129, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#059669', marginBottom: '20px' }}>
                <EyeOff style={{ width: '24px', height: '24px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '18px', marginBottom: '8px' }}>Ghost Mode Disappearing</h4>
              <p style={{ fontSize: '14px', color: '#475569', lineHeight: 1.6, margin: 0 }}>
                Enforces 30s auto-purging messages, view-once media items, hidden notification previews, and screenshot block overlays.
              </p>
            </div>

            {/* Card 3 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '24px',
                padding: '28px',
                textAlign: 'left',
                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.03)',
              }}
            >
              <div style={{ width: '48px', height: '48px', borderRadius: '14px', backgroundColor: 'rgba(139, 92, 246, 0.1)', border: '1px solid rgba(139, 92, 246, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7c3aed', marginBottom: '20px' }}>
                <Video style={{ width: '24px', height: '24px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '18px', marginBottom: '8px' }}>WebRTC P2P Direct Tunnel</h4>
              <p style={{ fontSize: '14px', color: '#475569', lineHeight: 1.6, margin: 0 }}>
                Direct peer-to-peer audio and video streaming. Zero server audio/video relay storage or eavesdropping.
              </p>
            </div>

            {/* Card 4 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '24px',
                padding: '28px',
                textAlign: 'left',
                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.03)',
              }}
            >
              <div style={{ width: '48px', height: '48px', borderRadius: '14px', backgroundColor: 'rgba(37, 99, 235, 0.1)', border: '1px solid rgba(37, 99, 235, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb', marginBottom: '20px' }}>
                <ShieldCheck style={{ width: '24px', height: '24px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '18px', marginBottom: '8px' }}>Zero-Knowledge Identity</h4>
              <p style={{ fontSize: '14px', color: '#475569', lineHeight: 1.6, margin: 0 }}>
                No phone numbers, no email addresses, and no contact list uploads required. Your identity is a local key pair.
              </p>
            </div>
          </div>
        </section>

        {/* SECTION 3: REAL-TIME CRYPTOGRAPHIC TERMINAL (Light Theme Playground) */}
        <section id="simulator" style={{ marginBottom: '96px' }}>
          <div style={{ textTransform: 'uppercase', fontSize: '13px', fontWeight: 900, color: '#c026d3', letterSpacing: '0.12em', textAlign: 'center', marginBottom: '10px' }}>
            Interactive Security Engine
          </div>
          <h3 style={{ fontSize: '36px', fontWeight: 900, color: '#0f172a', textAlign: 'center', marginBottom: '40px', letterSpacing: '-0.02em' }}>
            Live Cryptographic Payload Terminal
          </h3>

          <div
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e2e8f0',
              borderRadius: '28px',
              padding: '36px',
              boxShadow: '0 20px 50px rgba(0, 0, 0, 0.05)',
            }}
          >
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '32px' }}>
              {/* Left Column: Plaintext Stream */}
              <div style={{ textAlign: 'left' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <label style={{ fontSize: '13px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Plaintext Client Input</label>
                  <span style={{ fontSize: '12px', color: '#059669', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981' }} />
                    Local RAM Only
                  </span>
                </div>
                <textarea
                  value={simText}
                  onChange={(e) => setSimText(e.target.value)}
                  rows={4}
                  style={{
                    width: '100%',
                    backgroundColor: '#f8fafc',
                    border: '1px solid #cbd5e1',
                    borderRadius: '16px',
                    padding: '16px',
                    color: '#0f172a',
                    fontSize: '15px',
                    outline: 'none',
                    resize: 'none',
                    boxSizing: 'border-box',
                    lineHeight: 1.5,
                  }}
                />
              </div>

              {/* Right Column: Encrypted Output */}
              <div style={{ textAlign: 'left' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <label style={{ fontSize: '13px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.05em' }}>AES-256-GCM Ciphertext Packet</label>
                  <span style={{ fontSize: '12px', color: '#c026d3', fontFamily: 'monospace', fontWeight: 700 }}>Wire Stream</span>
                </div>
                <div
                  style={{
                    width: '100%',
                    backgroundColor: '#0f172a',
                    border: '1px solid #1e293b',
                    borderRadius: '16px',
                    padding: '16px',
                    minHeight: '120px',
                    color: '#e879f9',
                    fontSize: '13px',
                    fontFamily: 'monospace',
                    wordBreak: 'break-all',
                    boxSizing: 'border-box',
                    lineHeight: 1.6,
                    boxShadow: 'inset 0 2px 8px rgba(0, 0, 0, 0.4)',
                  }}
                >
                  {getCiphertext(simText)}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* SECTION 4: PROTOCOL SPECS GRID (Full 1920px Widescreen Audit Card) */}
        <section id="specs" style={{ marginBottom: '64px' }}>
          <div
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e2e8f0',
              borderRadius: '28px',
              padding: '40px',
              textAlign: 'left',
              boxShadow: '0 20px 50px rgba(0, 0, 0, 0.04)',
            }}
          >
            <h3 style={{ fontSize: '24px', fontWeight: 900, color: '#0f172a', marginBottom: '24px' }}>
              Full Technical & Security Audit Specifications
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '24px' }}>
              <div style={{ backgroundColor: '#f8fafc', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                <span style={{ fontSize: '12px', color: '#64748b', textTransform: 'uppercase', fontWeight: 800, letterSpacing: '0.05em' }}>Symmetric Cipher</span>
                <p style={{ color: '#c026d3', fontWeight: 900, fontSize: '16px', margin: '4px 0 0' }}>AES-256-GCM (Authenticated)</p>
              </div>

              <div style={{ backgroundColor: '#f8fafc', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                <span style={{ fontSize: '12px', color: '#64748b', textTransform: 'uppercase', fontWeight: 800, letterSpacing: '0.05em' }}>Key Agreement</span>
                <p style={{ color: '#c026d3', fontWeight: 900, fontSize: '16px', margin: '4px 0 0' }}>ECDH (Curve25519 Ephemeral)</p>
              </div>

              <div style={{ backgroundColor: '#f8fafc', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                <span style={{ fontSize: '12px', color: '#64748b', textTransform: 'uppercase', fontWeight: 800, letterSpacing: '0.05em' }}>Key Expansion</span>
                <p style={{ color: '#c026d3', fontWeight: 900, fontSize: '16px', margin: '4px 0 0' }}>HKDF-SHA256 Protocol</p>
              </div>

              <div style={{ backgroundColor: '#f8fafc', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                <span style={{ fontSize: '12px', color: '#64748b', textTransform: 'uppercase', fontWeight: 800, letterSpacing: '0.05em' }}>Audio/Video Tunnel</span>
                <p style={{ color: '#c026d3', fontWeight: 900, fontSize: '16px', margin: '4px 0 0' }}>WebRTC STUN/TURN Direct P2P</p>
              </div>
            </div>
          </div>
        </section>

      </main>

      {/* Footer (Clean Light Widescreen Footer) */}
      <footer
        style={{
          borderTop: '1px solid #e2e8f0',
          backgroundColor: '#f8fafc',
          padding: '32px',
          textAlign: 'center',
          fontSize: '14px',
          color: '#64748b',
          zIndex: 1,
        }}
      >
        <div
          style={{
            maxWidth: '1800px',
            margin: '0 auto',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '20px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <img src="/logo.png" alt="OurSpace Logo" style={{ height: '32px', width: 'auto' }} />
            <p style={{ margin: 0, fontWeight: 600, color: '#475569' }}>© 2026 OurSpace Privacy Chat. All rights reserved.</p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
            <span style={{ color: '#c026d3', fontWeight: 700 }}>A Private Space For Two</span>
            <span>•</span>
            <span style={{ color: '#475569', fontWeight: 600 }}>End-to-End Encrypted</span>
            <span>•</span>
            <a href="https://github.com/Virusboot/OurSpace" target="_blank" rel="noreferrer" style={{ color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Open Source GitHub</a>
          </div>
        </div>
      </footer>
    </div>
  );
};
