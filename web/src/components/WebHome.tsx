import React, { useState } from 'react';
import {
  Shield, Lock, Video, Phone, EyeOff, Key, Sparkles, ArrowRight,
  Copy, Check, Cpu, RefreshCw, Zap, Download, Activity,
  Globe, Server, Terminal, Radio, ShieldCheck, Heart, Users
} from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

export const WebHome: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'join' | 'create'>('join');
  const [inputToken, setInputToken] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  
  // Call Link Generator State
  const [callType, setCallType] = useState<'video' | 'audio'>('video');
  const [generatedLink, setGeneratedLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

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
      {/* Background Soft Purple Gradient Aura */}
      <div
        style={{
          position: 'fixed',
          top: '-10%',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '700px',
          height: '500px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(217, 70, 239, 0.06) 0%, rgba(139, 92, 246, 0.04) 50%, rgba(255, 255, 255, 0) 70%)',
          pointerEvents: 'none',
          zIndex: 0,
        }}
      />

      <Header />

      {/* Main Container (Centered 1280px Container with Exact 32px Side Margins Matching Header & Footer) */}
      <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '56px 32px', flex: 1, zIndex: 1, width: '100%', boxSizing: 'border-box' }}>
        
        {/* HERO SECTION: Balanced 2-Column Layout */}
        <section id="hub" style={{ marginBottom: '80px' }}>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
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
                  padding: '6px 16px',
                  borderRadius: '9999px',
                  backgroundColor: 'rgba(217, 70, 239, 0.08)',
                  border: '1px solid rgba(217, 70, 239, 0.2)',
                  color: '#c026d3',
                  fontSize: '12px',
                  fontWeight: 800,
                  letterSpacing: '0.04em',
                  textTransform: 'uppercase',
                  marginBottom: '20px',
                }}
              >
                <Heart style={{ width: '14px', height: '14px', fill: '#c026d3' }} />
                <span>A Private Space For Two • Zero-Knowledge E2EE</span>
              </div>

              <h2
                style={{
                  fontSize: 'clamp(32px, 3.8vw, 54px)',
                  fontWeight: 900,
                  color: '#0f172a',
                  marginBottom: '18px',
                  lineHeight: 1.15,
                  letterSpacing: '-0.03em',
                }}
              >
                Your Private Space for <br />
                <span style={{ background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  Ultra-Secure Encrypted Calls
                </span>
              </h2>

              <p style={{ color: '#475569', fontSize: '17px', lineHeight: 1.6, marginBottom: '32px', maxWidth: '560px' }}>
                Join or create end-to-end encrypted WebRTC video and audio calls. Zero phone numbers, zero contact sync, and absolute cryptographic privacy.
              </p>

              {/* Interactive Call Hub Card */}
              <div
                style={{
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '20px',
                  padding: '24px',
                  boxShadow: '0 15px 35px rgba(0, 0, 0, 0.04)',
                }}
              >
                {/* Tab Switches */}
                <div style={{ display: 'flex', backgroundColor: '#f8fafc', padding: '4px', borderRadius: '12px', marginBottom: '20px', border: '1px solid #e2e8f0' }}>
                  <button
                    onClick={() => setActiveTab('join')}
                    style={{
                      flex: 1,
                      padding: '10px',
                      borderRadius: '8px',
                      border: 'none',
                      fontSize: '13px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                      background: activeTab === 'join' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'join' ? '#ffffff' : '#64748b',
                      transition: 'all 0.2s ease',
                      boxShadow: activeTab === 'join' ? '0 4px 12px rgba(217, 70, 239, 0.25)' : 'none',
                    }}
                  >
                    Join Encrypted Room
                  </button>
                  <button
                    onClick={() => setActiveTab('create')}
                    style={{
                      flex: 1,
                      padding: '10px',
                      borderRadius: '8px',
                      border: 'none',
                      fontSize: '13px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                      background: activeTab === 'create' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'create' ? '#ffffff' : '#64748b',
                      transition: 'all 0.2s ease',
                      boxShadow: activeTab === 'create' ? '0 4px 12px rgba(217, 70, 239, 0.25)' : 'none',
                    }}
                  >
                    Generate Room Link
                  </button>
                </div>

                {/* TAB 1: JOIN CALL */}
                {activeTab === 'join' && (
                  <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: '11px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.04em' }}>Call Link or Token</span>
                      <span style={{ fontSize: '11px', color: '#c026d3', fontFamily: 'monospace', fontWeight: 700 }}>AES-256 P2P</span>
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
                          backgroundColor: '#f8fafc',
                          border: '1px solid #cbd5e1',
                          borderRadius: '12px',
                          padding: '12px 14px',
                          fontSize: '14px',
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
                          fontSize: '13px',
                          padding: '0 20px',
                          borderRadius: '12px',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                          boxShadow: '0 6px 16px rgba(217, 70, 239, 0.25)',
                        }}
                      >
                        <span>Join</span>
                        <ArrowRight style={{ width: '15px', height: '15px' }} />
                      </button>
                    </div>
                    {errorMsg && <p style={{ color: '#f43f5e', fontSize: '12px', textAlign: 'left', margin: 0, fontWeight: 600 }}>{errorMsg}</p>}
                  </form>
                )}

                {/* TAB 2: GENERATE LINK */}
                {activeTab === 'create' && (
                  <form onSubmit={handleGenerateCallLink} style={{ display: 'flex', flexDirection: 'column', gap: '14px', textAlign: 'left' }}>
                    <div>
                      <label style={{ fontSize: '11px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.04em', display: 'block', marginBottom: '8px' }}>Select Call Type</label>
                      <div style={{ display: 'flex', gap: '10px' }}>
                        <button
                          type="button"
                          onClick={() => setCallType('video')}
                          style={{
                            flex: 1,
                            padding: '10px',
                            borderRadius: '10px',
                            border: callType === 'video' ? '2px solid #d946ef' : '1px solid #cbd5e1',
                            backgroundColor: callType === 'video' ? 'rgba(217, 70, 239, 0.06)' : '#f8fafc',
                            color: '#0f172a',
                            fontSize: '13px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '6px',
                          }}
                        >
                          <Video style={{ width: '16px', height: '16px', color: '#c026d3' }} />
                          <span>HD Video</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => setCallType('audio')}
                          style={{
                            flex: 1,
                            padding: '10px',
                            borderRadius: '10px',
                            border: callType === 'audio' ? '2px solid #d946ef' : '1px solid #cbd5e1',
                            backgroundColor: callType === 'audio' ? 'rgba(217, 70, 239, 0.06)' : '#f8fafc',
                            color: '#0f172a',
                            fontSize: '13px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '6px',
                          }}
                        >
                          <Phone style={{ width: '16px', height: '16px', color: '#c026d3' }} />
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
                        fontSize: '14px',
                        padding: '12px',
                        borderRadius: '12px',
                        border: 'none',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '6px',
                        boxShadow: '0 6px 20px rgba(217, 70, 239, 0.3)',
                      }}
                    >
                      <Zap style={{ width: '16px', height: '16px' }} />
                      <span>Generate Encrypted Room Link</span>
                    </button>

                    {generatedLink && (
                      <div style={{ backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px' }}>
                        <span style={{ fontSize: '11px', color: '#64748b', display: 'block', marginBottom: '4px', fontWeight: 800 }}>GENERATED LINK:</span>
                        <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                          <input
                            type="text"
                            readOnly
                            value={generatedLink}
                            style={{ flex: 1, backgroundColor: 'transparent', border: 'none', color: '#c026d3', fontSize: '12px', fontFamily: 'monospace', outline: 'none', fontWeight: 700 }}
                          />
                          <button
                            type="button"
                            onClick={handleCopyLink}
                            style={{ backgroundColor: '#e2e8f0', border: 'none', padding: '6px 12px', borderRadius: '8px', color: '#0f172a', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
                          >
                            {copied ? <Check style={{ width: '14px', height: '14px', color: '#10b981' }} /> : <Copy style={{ width: '14px', height: '14px' }} />}
                            <span>{copied ? 'Copied' : 'Copy'}</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => { window.location.href = generatedLink; }}
                            style={{ backgroundColor: '#10b981', border: 'none', padding: '6px 14px', borderRadius: '8px', color: '#ffffff', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
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

            {/* RIGHT COLUMN: Ultra-Clean Light Mode WebRTC Mockup Window */}
            <div style={{ position: 'relative' }}>
              <div
                style={{
                  position: 'relative',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '24px',
                  padding: '20px',
                  boxShadow: '0 20px 40px rgba(0, 0, 0, 0.05)',
                  overflow: 'hidden',
                }}
              >
                {/* Mockup Header */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', borderBottom: '1px solid #f1f5f9', paddingBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#f43f5e', display: 'inline-block' }} />
                    <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#eab308', display: 'inline-block' }} />
                    <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block' }} />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.08)', border: '1px solid rgba(217, 70, 239, 0.2)' }}>
                    <Lock style={{ width: '12px', height: '12px', color: '#c026d3' }} />
                    <span style={{ fontSize: '11px', color: '#c026d3', fontWeight: 'bold' }}>AES-256-GCM WebRTC Call</span>
                  </div>
                </div>

                {/* Light Purple Mockup Video Display Canvas */}
                <div
                  style={{
                    height: '280px',
                    borderRadius: '16px',
                    background: 'linear-gradient(135deg, #faf5ff 0%, #f3e8ff 100%)',
                    border: '1px solid #e9d5ff',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    position: 'relative',
                    overflow: 'hidden',
                  }}
                >
                  <div style={{ width: '76px', height: '76px', borderRadius: '50%', background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff', fontSize: '28px', fontWeight: 'bold', marginBottom: '14px', boxShadow: '0 10px 25px rgba(217, 70, 239, 0.35)', zIndex: 1 }}>
                    🔒
                  </div>

                  <h4 style={{ color: '#0f172a', fontSize: '16px', fontWeight: 'bold', margin: '0 0 4px', zIndex: 1 }}>
                    Private Space Encrypted Channel
                  </h4>
                  <p style={{ color: '#059669', fontSize: '12px', fontWeight: 700, margin: 0, zIndex: 1, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981' }} />
                    Direct P2P STUN Tunnel • 0% Relay Storage
                  </p>

                  {/* Floating Action Controls */}
                  <div style={{ position: 'absolute', bottom: '16px', display: 'flex', gap: '14px', zIndex: 2 }}>
                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#ffffff', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#475569', boxShadow: '0 4px 10px rgba(0,0,0,0.05)' }}>
                      <Phone style={{ width: '16px', height: '16px' }} />
                    </div>
                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#ffffff', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#475569', boxShadow: '0 4px 10px rgba(0,0,0,0.05)' }}>
                      <Video style={{ width: '16px', height: '16px' }} />
                    </div>
                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#f43f5e', border: '1px solid #f43f5e', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff', boxShadow: '0 4px 10px rgba(244,63,94,0.3)' }}>
                      <Phone style={{ width: '16px', height: '16px', transform: 'rotate(135deg)' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* SECTION 2: 4-COLUMN FEATURE GRID (Light Theme Cards) */}
        <section id="features" style={{ marginBottom: '80px' }}>
          <div style={{ textTransform: 'uppercase', fontSize: '12px', fontWeight: 900, color: '#c026d3', letterSpacing: '0.1em', textAlign: 'center', marginBottom: '8px' }}>
            Zero-Trust Architectural Principles
          </div>
          <h3 style={{ fontSize: '32px', fontWeight: 900, color: '#0f172a', textAlign: 'center', marginBottom: '40px', letterSpacing: '-0.02em' }}>
            Uncompromising Security & Privacy Standards
          </h3>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
              gap: '20px',
            }}
          >
            {/* Card 1 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '20px',
                padding: '24px',
                textAlign: 'left',
                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.02)',
              }}
            >
              <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: 'rgba(217, 70, 239, 0.08)', border: '1px solid rgba(217, 70, 239, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#c026d3', marginBottom: '16px' }}>
                <Lock style={{ width: '22px', height: '22px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '17px', marginBottom: '6px' }}>AES-256-GCM + ECDH</h4>
              <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5, margin: 0 }}>
                Every message payload, voice frame, and video stream is encrypted locally on your device prior to network transport.
              </p>
            </div>

            {/* Card 2 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '20px',
                padding: '24px',
                textAlign: 'left',
                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.02)',
              }}
            >
              <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#059669', marginBottom: '16px' }}>
                <EyeOff style={{ width: '22px', height: '22px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '17px', marginBottom: '6px' }}>Ghost Mode Disappearing</h4>
              <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5, margin: 0 }}>
                Enforces 30s auto-purging messages, view-once media items, hidden notification previews, and screenshot block overlays.
              </p>
            </div>

            {/* Card 3 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '20px',
                padding: '24px',
                textAlign: 'left',
                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.02)',
              }}
            >
              <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: 'rgba(139, 92, 246, 0.08)', border: '1px solid rgba(139, 92, 246, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7c3aed', marginBottom: '16px' }}>
                <Video style={{ width: '22px', height: '22px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '17px', marginBottom: '6px' }}>WebRTC P2P Direct Tunnel</h4>
              <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5, margin: 0 }}>
                Direct peer-to-peer audio and video streaming. Zero server audio/video relay storage or eavesdropping.
              </p>
            </div>

            {/* Card 4 */}
            <div
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '20px',
                padding: '24px',
                textAlign: 'left',
                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.02)',
              }}
            >
              <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: 'rgba(37, 99, 235, 0.08)', border: '1px solid rgba(37, 99, 235, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb', marginBottom: '16px' }}>
                <ShieldCheck style={{ width: '22px', height: '22px' }} />
              </div>
              <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '17px', marginBottom: '6px' }}>Zero-Knowledge Identity</h4>
              <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5, margin: 0 }}>
                No phone numbers, no email addresses, and no contact list uploads required. Your identity is a local key pair.
              </p>
            </div>
          </div>
        </section>

      </main>

      <Footer />
    </div>
  );
};
