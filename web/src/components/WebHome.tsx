import React, { useState } from 'react';
import { Shield, Lock, Video, Phone, EyeOff, Key, Sparkles, ArrowRight } from 'lucide-react';

export const WebHome: React.FC = () => {
  const [inputToken, setInputToken] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

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

  return (
    <div
      className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between"
      style={{
        minHeight: '100vh',
        backgroundColor: '#030712',
        color: '#f3f4f6',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        fontFamily: 'Inter, system-ui, sans-serif',
      }}
    >
      {/* Navigation Header */}
      <header
        className="border-b border-slate-800 bg-slate-950/90 backdrop-blur-md sticky top-0 z-50 px-6 py-4"
        style={{
          borderBottom: '1px solid #1e293b',
          backgroundColor: 'rgba(3, 7, 18, 0.9)',
          padding: '16px 24px',
          position: 'sticky',
          top: 0,
          zIndex: 50,
        }}
      >
        <div
          className="max-w-6xl mx-auto flex items-center justify-between"
          style={{
            maxWidth: '1152px',
            margin: '0 auto',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div className="flex items-center space-x-3" style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              className="w-10 h-10 rounded-xl bg-blue-600/20 border border-blue-500/40 flex items-center justify-center"
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '12px',
                backgroundColor: 'rgba(37, 99, 235, 0.2)',
                border: '1px solid rgba(59, 130, 246, 0.4)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Shield className="w-5 h-5 text-blue-500" style={{ color: '#3b82f6', width: '20px', height: '20px' }} />
            </div>
            <div>
              <h1 className="font-bold text-lg text-white" style={{ fontWeight: 'bold', fontSize: '18px', color: '#ffffff' }}>
                OurSpace{' '}
                <span
                  style={{
                    fontSize: '11px',
                    padding: '2px 8px',
                    borderRadius: '9999px',
                    backgroundColor: 'rgba(59, 130, 246, 0.15)',
                    border: '1px solid rgba(59, 130, 246, 0.4)',
                    color: '#60a5fa',
                  }}
                >
                  E2EE
                </span>
              </h1>
            </div>
          </div>

          <div className="flex items-center space-x-4" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <a
              href="https://github.com/Virusboot/OurSpace"
              target="_blank"
              rel="noreferrer"
              style={{ fontSize: '12px', color: '#94a3b8', textDecoration: 'none', fontWeight: 600 }}
            >
              GitHub Source
            </a>
            <button
              onClick={() => alert('OurSpace App v1.0.0 is built with Zero-Knowledge E2EE Architecture.')}
              style={{
                fontSize: '12px',
                fontWeight: 'bold',
                padding: '8px 16px',
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
        </div>
      </header>

      {/* Main Hero Container */}
      <main
        className="max-w-4xl mx-auto px-6 py-12 flex-1 flex flex-col items-center justify-center text-center"
        style={{
          maxWidth: '896px',
          margin: '0 auto',
          padding: '48px 24px',
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
        }}
      >
        {/* Security Badge */}
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '6px 14px',
            borderRadius: '9999px',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            border: '1px solid rgba(59, 130, 246, 0.25)',
            color: '#60a5fa',
            fontSize: '12px',
            fontWeight: 'bold',
            marginBottom: '24px',
          }}
        >
          <Sparkles style={{ width: '14px', height: '14px' }} />
          <span>Zero-Knowledge Peer-to-Peer Encryption</span>
        </div>

        {/* Hero Title */}
        <h2
          style={{
            fontSize: '36px',
            fontWeight: 900,
            color: '#ffffff',
            marginBottom: '16px',
            lineHeight: 1.2,
            letterSpacing: '-0.02em',
          }}
        >
          Ultra-Private Calls & <br />
          <span style={{ color: '#60a5fa' }}>Secure Communications</span>
        </h2>

        <p style={{ color: '#94a3b8', fontSize: '16px', maxWidth: '640px', marginBottom: '32px', lineHeight: 1.6 }}>
          Join E2EE WebRTC voice and video calls with zero registration, zero phone numbers, and complete cryptographic privacy.
        </p>

        {/* Call Link / Token Input Card */}
        <div
          style={{
            width: '100%',
            maxWidth: '448px',
            backgroundColor: '#0f172a',
            border: '1px solid #1e293b',
            borderRadius: '16px',
            padding: '24px',
            marginBottom: '48px',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
          }}
        >
          <form onSubmit={handleJoinByToken} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <label
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                fontSize: '12px',
                fontWeight: 'bold',
                color: '#cbd5e1',
                textTransform: 'uppercase',
              }}
            >
              <span>Join Encrypted Call</span>
              <span style={{ color: '#60a5fa', fontFamily: 'monospace' }}>P2P Room</span>
            </label>
            <div style={{ display: 'flex', gap: '8px' }}>
              <input
                type="text"
                value={inputToken}
                onChange={(e) => {
                  setInputToken(e.target.value);
                  setErrorMsg('');
                }}
                placeholder="Paste Call Link or Token (e.g. c/token)"
                style={{
                  flex: 1,
                  backgroundColor: '#020617',
                  border: '1px solid #334155',
                  borderRadius: '10px',
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
                  borderRadius: '10px',
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
        </div>

        {/* Feature Highlights Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', width: '100%', textAlign: 'left' }}>
          <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.6)', border: '1px solid #1e293b', padding: '20px', borderRadius: '16px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: 'rgba(59, 130, 246, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#60a5fa', marginBottom: '12px' }}>
              <Lock style={{ width: '18px', height: '18px' }} />
            </div>
            <h3 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '14px', marginBottom: '4px' }}>AES-256-GCM E2EE</h3>
            <p style={{ fontSize: '12px', color: '#94a3b8', lineHeight: 1.5, margin: 0 }}>
              Messages and media streams are encrypted on device before transmission.
            </p>
          </div>

          <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.6)', border: '1px solid #1e293b', padding: '20px', borderRadius: '16px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: 'rgba(16, 185, 129, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#34d399', marginBottom: '12px' }}>
              <EyeOff style={{ width: '18px', height: '18px' }} />
            </div>
            <h3 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '14px', marginBottom: '4px' }}>Ghost Mode & Disappearing</h3>
            <p style={{ fontSize: '12px', color: '#94a3b8', lineHeight: 1.5, margin: 0 }}>
              30s self-destructing timers and screenshot overlay protection.
            </p>
          </div>

          <div style={{ backgroundColor: 'rgba(15, 23, 42, 0.6)', border: '1px solid #1e293b', padding: '20px', borderRadius: '16px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: 'rgba(99, 102, 241, 0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#818cf8', marginBottom: '12px' }}>
              <Video style={{ width: '18px', height: '18px' }} />
            </div>
            <h3 style={{ fontWeight: 'bold', color: '#ffffff', fontSize: '14px', marginBottom: '4px' }}>WebRTC P2P Voice & Video</h3>
            <p style={{ fontSize: '12px', color: '#94a3b8', lineHeight: 1.5, margin: 0 }}>
              Direct peer-to-peer encrypted calls with zero server audio/video relay storage.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer style={{ borderTop: '1px solid #1e293b', padding: '24px', textAlign: 'center', fontSize: '12px', color: '#64748b' }}>
        <div style={{ maxWidth: '1152px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
          <p style={{ margin: 0 }}>© 2026 OurSpace Privacy Chat. All rights reserved.</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ color: '#60a5fa', fontWeight: 600 }}>Zero Logs Policy</span>
            <span>•</span>
            <span style={{ color: '#94a3b8' }}>End-to-End Encrypted</span>
          </div>
        </div>
      </footer>
    </div>
  );
};
