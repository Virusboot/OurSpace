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

  const handleGenerateCallLink = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/call-links/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ callType, durationMinutes: 60 })
      });
      const data = await res.json();
      if (data && data.token) {
        setGeneratedLink(`${window.location.origin}/c/${data.token}`);
      } else {
        const fallback = 'room_' + Math.random().toString(36).substring(2, 10);
        setGeneratedLink(`${window.location.origin}/c/${fallback}`);
      }
    } catch (_) {
      const fallback = 'room_' + Math.random().toString(36).substring(2, 10);
      setGeneratedLink(`${window.location.origin}/c/${fallback}`);
    }
  };

  const handleCopyLink = () => {
    if (!generatedLink) return;
    navigator.clipboard.writeText(generatedLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const features = [
    {
      icon: <Lock size={22} />, color: '#c026d3', bg: 'rgba(217,70,239,0.08)', border: 'rgba(217,70,239,0.2)',
      title: 'AES-256-GCM + ECDH',
      desc: 'Every message payload, voice frame, and video stream is encrypted locally on your device prior to network transport.',
    },
    {
      icon: <EyeOff size={22} />, color: '#059669', bg: 'rgba(16,185,129,0.08)', border: 'rgba(16,185,129,0.2)',
      title: 'Ghost Mode Disappearing',
      desc: 'Enforces 30s auto-purging messages, view-once media items, hidden notification previews, and screenshot block overlays.',
    },
    {
      icon: <Video size={22} />, color: '#7c3aed', bg: 'rgba(139,92,246,0.08)', border: 'rgba(139,92,246,0.2)',
      title: 'WebRTC P2P Direct Tunnel',
      desc: 'Direct peer-to-peer audio and video streaming. Zero server audio/video relay storage or eavesdropping.',
    },
    {
      icon: <ShieldCheck size={22} />, color: '#2563eb', bg: 'rgba(37,99,235,0.08)', border: 'rgba(37,99,235,0.2)',
      title: 'Zero-Knowledge Identity',
      desc: 'No phone numbers, no email addresses, and no contact list uploads required. Your identity is a local key pair.',
    },
  ];

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff', color: '#0f172a', display: 'flex', flexDirection: 'column', fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif", position: 'relative', overflowX: 'hidden' }}>

      {/* Background Aura */}
      <div style={{ position: 'fixed', top: '-10%', left: '50%', transform: 'translateX(-50%)', width: 'min(700px, 100vw)', height: '500px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(217,70,239,0.06) 0%, rgba(139,92,246,0.04) 50%, rgba(255,255,255,0) 70%)', pointerEvents: 'none', zIndex: 0 }} />

      <Header />

      <main className="main-content">

        {/* ── HERO SECTION ── */}
        <section className="section">
          <div className="hero-grid">

            {/* LEFT: Hero copy + Call Hub */}
            <div style={{ textAlign: 'left' }}>
              {/* Badge */}
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '6px 16px', borderRadius: '9999px', backgroundColor: 'rgba(217,70,239,0.08)', border: '1px solid rgba(217,70,239,0.2)', color: '#c026d3', fontSize: '12px', fontWeight: 800, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: '20px' }}>
                <Heart style={{ width: '14px', height: '14px', fill: '#c026d3' }} />
                <span>A Private Space For Two • Zero-Knowledge E2EE</span>
              </div>

              <h1 className="hero-title">
                Your Private Space for{' '}
                <span style={{ display: 'block', background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  Ultra-Secure Encrypted Calls
                </span>
              </h1>

              <p className="hero-subtitle">
                Join or create end-to-end encrypted WebRTC video and audio calls. Zero phone numbers, zero contact sync, and absolute cryptographic privacy.
              </p>

              {/* Call Hub Card */}
              <div className="call-hub-card">
                {/* Tabs */}
                <div className="tab-row">
                  <button
                    className="tab-btn"
                    onClick={() => setActiveTab('join')}
                    style={{
                      background: activeTab === 'join' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'join' ? '#fff' : '#64748b',
                      boxShadow: activeTab === 'join' ? '0 4px 12px rgba(217,70,239,0.25)' : 'none',
                    }}
                  >
                    Join Encrypted Room
                  </button>
                  <button
                    className="tab-btn"
                    onClick={() => setActiveTab('create')}
                    style={{
                      background: activeTab === 'create' ? 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)' : 'transparent',
                      color: activeTab === 'create' ? '#fff' : '#64748b',
                      boxShadow: activeTab === 'create' ? '0 4px 12px rgba(217,70,239,0.25)' : 'none',
                    }}
                  >
                    Generate Room Link
                  </button>
                </div>

                {/* TAB: JOIN */}
                {activeTab === 'join' && (
                  <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '4px' }}>
                      <span style={{ fontSize: '11px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.04em' }}>Call Link or Token</span>
                      <span style={{ fontSize: '11px', color: '#c026d3', fontFamily: 'monospace', fontWeight: 700 }}>AES-256 P2P</span>
                    </div>
                    <div className="join-input-row">
                      <input
                        type="text"
                        value={inputToken}
                        onChange={(e) => { setInputToken(e.target.value); setErrorMsg(''); }}
                        placeholder="Paste link e.g. /c/room_xyz123"
                        style={{ flex: 1, backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px 14px', fontSize: '14px', color: '#0f172a', outline: 'none', minWidth: 0 }}
                      />
                      <button
                        type="submit"
                        style={{ background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)', color: '#fff', fontWeight: 'bold', fontSize: '13px', padding: '12px 20px', borderRadius: '12px', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', boxShadow: '0 6px 16px rgba(217,70,239,0.25)', whiteSpace: 'nowrap' }}
                      >
                        <span>Join</span>
                        <ArrowRight style={{ width: '15px', height: '15px' }} />
                      </button>
                    </div>
                    {errorMsg && <p style={{ color: '#f43f5e', fontSize: '12px', margin: 0, fontWeight: 600 }}>{errorMsg}</p>}
                  </form>
                )}

                {/* TAB: GENERATE */}
                {activeTab === 'create' && (
                  <form onSubmit={handleGenerateCallLink} style={{ display: 'flex', flexDirection: 'column', gap: '14px', textAlign: 'left' }}>
                    <div>
                      <label style={{ fontSize: '11px', fontWeight: 800, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.04em', display: 'block', marginBottom: '8px' }}>Select Call Type</label>
                      <div style={{ display: 'flex', gap: '10px' }}>
                        {(['video', 'audio'] as const).map((type) => (
                          <button
                            key={type}
                            type="button"
                            onClick={() => setCallType(type)}
                            style={{ flex: 1, padding: '10px', borderRadius: '10px', border: callType === type ? '2px solid #d946ef' : '1px solid #cbd5e1', backgroundColor: callType === type ? 'rgba(217,70,239,0.06)' : '#f8fafc', color: '#0f172a', fontSize: '13px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}
                          >
                            {type === 'video' ? <Video style={{ width: '16px', height: '16px', color: '#c026d3' }} /> : <Phone style={{ width: '16px', height: '16px', color: '#c026d3' }} />}
                            <span>{type === 'video' ? 'HD Video' : 'Audio Only'}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    <button
                      type="submit"
                      style={{ background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)', color: '#fff', fontWeight: 'bold', fontSize: '14px', padding: '12px', borderRadius: '12px', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', boxShadow: '0 6px 20px rgba(217,70,239,0.3)' }}
                    >
                      <Zap style={{ width: '16px', height: '16px' }} />
                      <span>Generate Encrypted Room Link</span>
                    </button>

                    {generatedLink && (
                      <div style={{ backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px' }}>
                        <span style={{ fontSize: '11px', color: '#64748b', display: 'block', marginBottom: '4px', fontWeight: 800 }}>GENERATED LINK:</span>
                        <div style={{ display: 'flex', gap: '6px', alignItems: 'center', flexWrap: 'wrap' }}>
                          <input
                            type="text"
                            readOnly
                            value={generatedLink}
                            style={{ flex: 1, backgroundColor: 'transparent', border: 'none', color: '#c026d3', fontSize: '12px', fontFamily: 'monospace', outline: 'none', fontWeight: 700, minWidth: '0', width: '100%' }}
                          />
                          <div style={{ display: 'flex', gap: '6px' }}>
                            <button type="button" onClick={handleCopyLink} style={{ backgroundColor: '#e2e8f0', border: 'none', padding: '6px 12px', borderRadius: '8px', color: '#0f172a', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}>
                              {copied ? <Check style={{ width: '14px', height: '14px', color: '#10b981' }} /> : <Copy style={{ width: '14px', height: '14px' }} />}
                              <span>{copied ? 'Copied' : 'Copy'}</span>
                            </button>
                            <button type="button" onClick={() => { window.location.href = generatedLink; }} style={{ backgroundColor: '#10b981', border: 'none', padding: '6px 14px', borderRadius: '8px', color: '#fff', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer', whiteSpace: 'nowrap' }}>
                              Enter
                            </button>
                          </div>
                        </div>
                      </div>
                    )}
                  </form>
                )}
              </div>
            </div>

            {/* RIGHT: Mockup Window */}
            <div style={{ position: 'relative' }}>
              <div className="mockup-window">
                {/* Window controls */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', borderBottom: '1px solid #f1f5f9', paddingBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    {['#f43f5e', '#eab308', '#10b981'].map((c) => (
                      <span key={c} style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: c, display: 'inline-block' }} />
                    ))}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '20px', backgroundColor: 'rgba(217,70,239,0.08)', border: '1px solid rgba(217,70,239,0.2)' }}>
                    <Lock style={{ width: '12px', height: '12px', color: '#c026d3' }} />
                    <span style={{ fontSize: '11px', color: '#c026d3', fontWeight: 'bold' }}>AES-256-GCM WebRTC Call</span>
                  </div>
                </div>

                {/* Video canvas mockup */}
                <div className="mockup-video">
                  <div style={{ width: '76px', height: '76px', borderRadius: '50%', background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '28px', marginBottom: '14px', boxShadow: '0 10px 25px rgba(217,70,239,0.35)', zIndex: 1 }}>
                    🔒
                  </div>
                  <h4 style={{ color: '#0f172a', fontSize: '16px', fontWeight: 'bold', margin: '0 0 4px', zIndex: 1, textAlign: 'center', padding: '0 16px' }}>
                    Private Space Encrypted Channel
                  </h4>
                  <p style={{ color: '#059669', fontSize: '12px', fontWeight: 700, margin: 0, zIndex: 1, display: 'flex', alignItems: 'center', gap: '6px', textAlign: 'center' }}>
                    <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981', flexShrink: 0 }} />
                    Direct P2P STUN Tunnel • 0% Relay Storage
                  </p>
                  {/* Floating controls */}
                  <div style={{ position: 'absolute', bottom: '16px', display: 'flex', gap: '14px', zIndex: 2 }}>
                    {[Phone, Video].map((Icon, i) => (
                      <div key={i} style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#fff', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#475569', boxShadow: '0 4px 10px rgba(0,0,0,0.05)' }}>
                        <Icon style={{ width: '16px', height: '16px' }} />
                      </div>
                    ))}
                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#f43f5e', border: '1px solid #f43f5e', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', boxShadow: '0 4px 10px rgba(244,63,94,0.3)' }}>
                      <Phone style={{ width: '16px', height: '16px', transform: 'rotate(135deg)' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ── FEATURES SECTION ── */}
        <section className="section">
          <div style={{ textTransform: 'uppercase', fontSize: '12px', fontWeight: 900, color: '#c026d3', letterSpacing: '0.1em', textAlign: 'center', marginBottom: '8px' }}>
            Zero-Trust Architectural Principles
          </div>
          <h2 className="section-title">
            Uncompromising Security & Privacy Standards
          </h2>

          <div className="feature-grid">
            {features.map((f, i) => (
              <div key={i} className="feature-card">
                <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: f.bg, border: `1px solid ${f.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: f.color, marginBottom: '16px' }}>
                  {f.icon}
                </div>
                <h4 style={{ fontWeight: 900, color: '#0f172a', fontSize: '17px', marginBottom: '6px' }}>{f.title}</h4>
                <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5, margin: 0 }}>{f.desc}</p>
              </div>
            ))}
          </div>
        </section>

      </main>

      <Footer />
    </div>
  );
};
