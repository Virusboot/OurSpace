import React, { useState } from 'react';
import {
  Lock, Video, Phone, EyeOff,
  ArrowRight, Copy, Check, Zap, ShieldCheck, Heart
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
    if (!trimmed) { setErrorMsg('Please enter a valid call link or token'); return; }
    if (trimmed.includes('/c/')) {
      window.location.href = `/c/${trimmed.split('/c/')[1]}`;
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
        body: JSON.stringify({ callType, durationMinutes: 60 }),
      });
      const data = await res.json();
      const tok = data?.token || 'room_' + Math.random().toString(36).substring(2, 10);
      setGeneratedLink(`${window.location.origin}/c/${tok}`);
    } catch {
      setGeneratedLink(`${window.location.origin}/c/room_${Math.random().toString(36).substring(2, 10)}`);
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
      icon: <Lock size={22} />, color: '#c026d3',
      bg: 'rgba(217,70,239,0.08)', border: 'rgba(217,70,239,0.2)',
      title: 'AES-256-GCM + ECDH',
      desc: 'Every message payload, voice frame, and video stream is encrypted locally on your device prior to network transport.',
    },
    {
      icon: <EyeOff size={22} />, color: '#059669',
      bg: 'rgba(16,185,129,0.08)', border: 'rgba(16,185,129,0.2)',
      title: 'Ghost Mode Disappearing',
      desc: 'Enforces 30s auto-purging messages, view-once media items, hidden notification previews, and screenshot block overlays.',
    },
    {
      icon: <Video size={22} />, color: '#7c3aed',
      bg: 'rgba(139,92,246,0.08)', border: 'rgba(139,92,246,0.2)',
      title: 'WebRTC P2P Direct Tunnel',
      desc: 'Direct peer-to-peer audio and video streaming. Zero server audio/video relay storage or eavesdropping.',
    },
    {
      icon: <ShieldCheck size={22} />, color: '#2563eb',
      bg: 'rgba(37,99,235,0.08)', border: 'rgba(37,99,235,0.2)',
      title: 'Zero-Knowledge Identity',
      desc: 'No phone numbers, no email addresses, and no contact list uploads required. Your identity is a local key pair.',
    },
  ];

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', overflowX: 'hidden' }}>
      {/* Background aura */}
      <div style={{ position: 'fixed', top: '-5%', left: '50%', transform: 'translateX(-50%)', width: 'min(600px,100vw)', height: '400px', borderRadius: '50%', background: 'radial-gradient(circle, rgba(217,70,239,0.06) 0%, transparent 70%)', pointerEvents: 'none', zIndex: 0 }} />

      <Header />

      <main className="main-content">

        {/* ── HERO ── */}
        <section style={{ marginBottom: 0 }}>
          <div className="hero-grid">

            {/* LEFT COLUMN */}
            <div>
              {/* Badge */}
              <div className="hero-badge">
                <Heart size={13} fill="#c026d3" />
                <span>A Private Space For Two · Zero-Knowledge E2EE</span>
              </div>

              {/* Heading */}
              <h1 className="hero-title">
                Your Private Space for{' '}
                <span style={{ display: 'block', background: 'linear-gradient(135deg,#d946ef 0%,#8b5cf6 50%,#2563eb 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  Ultra-Secure Encrypted Calls
                </span>
              </h1>

              {/* Description */}
              <p className="hero-desc">
                Join or create end-to-end encrypted WebRTC video and audio calls. Zero phone numbers, zero contact sync, and absolute cryptographic privacy.
              </p>

              {/* ── CALL HUB CARD ── */}
              <div className="call-hub-card">

                {/* Tab switcher */}
                <div className="tab-row">
                  {(['join', 'create'] as const).map((tab) => (
                    <button
                      key={tab}
                      className="tab-btn"
                      onClick={() => setActiveTab(tab)}
                      style={{
                        background: activeTab === tab
                          ? 'linear-gradient(135deg,#d946ef 0%,#8b5cf6 100%)'
                          : 'transparent',
                        color: activeTab === tab ? '#fff' : '#64748b',
                        boxShadow: activeTab === tab ? '0 4px 12px rgba(217,70,239,0.25)' : 'none',
                      }}
                    >
                      {tab === 'join' ? 'Join Encrypted Room' : 'Generate Room Link'}
                    </button>
                  ))}
                </div>

                {/* TAB: JOIN */}
                {activeTab === 'join' && (
                  <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    <div className="form-label-row">
                      <span className="form-label">Call Link or Token</span>
                      <span className="form-tag">AES-256 P2P</span>
                    </div>
                    <div className="join-input-row">
                      <input
                        type="text"
                        value={inputToken}
                        onChange={(e) => { setInputToken(e.target.value); setErrorMsg(''); }}
                        placeholder="Paste link e.g. /c/room_xyz123"
                        className="join-input"
                      />
                      <button type="submit" className="join-btn">
                        <span>Join</span>
                        <ArrowRight size={15} />
                      </button>
                    </div>
                    {errorMsg && (
                      <p style={{ color: '#f43f5e', fontSize: '12px', margin: 0, fontWeight: 600 }}>{errorMsg}</p>
                    )}
                  </form>
                )}

                {/* TAB: GENERATE */}
                {activeTab === 'create' && (
                  <form onSubmit={handleGenerateCallLink} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: '8px' }}>Select Call Type</label>
                      <div className="call-type-row">
                        {(['video', 'audio'] as const).map((type) => (
                          <button
                            key={type}
                            type="button"
                            className="call-type-btn"
                            onClick={() => setCallType(type)}
                            style={{
                              border: callType === type ? '2px solid #d946ef' : '1px solid #cbd5e1',
                              backgroundColor: callType === type ? 'rgba(217,70,239,0.06)' : '#f8fafc',
                              color: '#0f172a',
                            }}
                          >
                            {type === 'video'
                              ? <Video size={16} color="#c026d3" />
                              : <Phone size={16} color="#c026d3" />}
                            <span>{type === 'video' ? 'HD Video' : 'Audio Only'}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    <button type="submit" className="generate-btn">
                      <Zap size={16} />
                      <span>Generate Encrypted Room Link</span>
                    </button>

                    {generatedLink && (
                      <div className="link-box">
                        <span style={{ fontSize: '10px', color: '#64748b', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Generated Link:</span>
                        <div className="link-box-actions">
                          <input type="text" readOnly value={generatedLink} className="link-display" />
                          <button type="button" onClick={handleCopyLink} className="copy-btn">
                            {copied ? <Check size={13} color="#10b981" /> : <Copy size={13} />}
                            <span>{copied ? 'Copied' : 'Copy'}</span>
                          </button>
                          <button type="button" onClick={() => { window.location.href = generatedLink; }} className="enter-btn">
                            Enter
                          </button>
                        </div>
                      </div>
                    )}
                  </form>
                )}
              </div>
            </div>

            {/* RIGHT COLUMN — Mockup */}
            <div>
              <div className="mockup-window">
                {/* Titlebar */}
                <div className="mockup-titlebar">
                  <div className="mockup-dots">
                    {['#f43f5e', '#eab308', '#10b981'].map((c) => (
                      <span key={c} className="mockup-dot" style={{ backgroundColor: c }} />
                    ))}
                  </div>
                  <div className="mockup-badge">
                    <Lock size={12} color="#c026d3" />
                    <span style={{ fontSize: '11px', color: '#c026d3', fontWeight: 'bold' }}>AES-256-GCM WebRTC Call</span>
                  </div>
                </div>

                {/* Video area */}
                <div className="mockup-video">
                  <div style={{ width: '72px', height: '72px', borderRadius: '50%', background: 'linear-gradient(135deg,#d946ef 0%,#8b5cf6 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', marginBottom: '12px', boxShadow: '0 10px 25px rgba(217,70,239,0.35)' }}>
                    🔒
                  </div>
                  <h3 style={{ color: '#0f172a', fontSize: '15px', fontWeight: 800, margin: '0 0 6px', textAlign: 'center', padding: '0 8px' }}>
                    Private Space Encrypted Channel
                  </h3>
                  <p style={{ color: '#059669', fontSize: '12px', fontWeight: 700, margin: 0, display: 'flex', alignItems: 'center', gap: '5px', textAlign: 'center' }}>
                    <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#10b981', flexShrink: 0 }} />
                    Direct P2P STUN Tunnel · 0% Relay
                  </p>

                  {/* Controls */}
                  <div className="mockup-controls">
                    {[Phone, Video].map((Icon, i) => (
                      <div key={i} className="mockup-ctrl-btn" style={{ backgroundColor: '#fff', border: '1px solid #e2e8f0', color: '#475569', boxShadow: '0 4px 10px rgba(0,0,0,0.05)' }}>
                        <Icon size={16} />
                      </div>
                    ))}
                    <div className="mockup-ctrl-btn" style={{ backgroundColor: '#f43f5e', border: '1px solid #f43f5e', color: '#fff', boxShadow: '0 4px 10px rgba(244,63,94,0.3)' }}>
                      <Phone size={16} style={{ transform: 'rotate(135deg)' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ── FEATURES SECTION ── */}
        <section style={{ marginTop: '64px', paddingBottom: '24px' }}>
          <p className="section-eyebrow">Zero-Trust Architectural Principles</p>
          <h2 className="section-title">Uncompromising Security & Privacy Standards</h2>

          <div className="feature-grid">
            {features.map((f, i) => (
              <div key={i} className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: f.bg, border: `1px solid ${f.border}`, color: f.color }}>
                  {f.icon}
                </div>
                <h4 className="feature-title">{f.title}</h4>
                <p className="feature-desc">{f.desc}</p>
              </div>
            ))}
          </div>
        </section>

      </main>

      <Footer />
    </div>
  );
};
