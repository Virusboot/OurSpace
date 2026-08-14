import React from 'react';
import { Heart, Lock, Video, EyeOff } from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

export const AboutUs: React.FC = () => {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff', color: '#0f172a', fontFamily: "'Inter', sans-serif", display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
      <Header />

      {/* Main Content */}
      <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '48px 32px', textAlign: 'left', flex: 1, width: '100%', boxSizing: 'border-box' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.08)', color: '#c026d3', fontSize: '12px', fontWeight: 800, marginBottom: '16px' }}>
          <Heart style={{ width: '14px', height: '14px', fill: '#c026d3' }} />
          <span>A Private Space For Two</span>
        </div>

        <h1 style={{ fontSize: '36px', fontWeight: 900, marginBottom: '8px', color: '#0f172a' }}>About OurSpace</h1>
        <p style={{ color: '#64748b', fontSize: '16px', marginBottom: '32px', lineHeight: 1.6 }}>
          OurSpace (v1.0.0) is designed to provide an ultra-secure, zero-knowledge private space for two individuals to communicate with complete cryptographic confidentiality.
        </p>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '20px', marginBottom: '40px' }}>
          <div style={{ backgroundColor: '#f8fafc', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <Lock style={{ width: '24px', height: '24px', color: '#c026d3', marginBottom: '12px' }} />
            <h3 style={{ fontSize: '16px', fontWeight: 800, margin: '0 0 6px' }}>AES-256-GCM</h3>
            <p style={{ fontSize: '13px', color: '#64748b', margin: 0, lineHeight: 1.5 }}>
              On-device client encryption ensures your messages are converted into unbreakable ciphertext before hitting the wire.
            </p>
          </div>

          <div style={{ backgroundColor: '#f8fafc', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <Video style={{ width: '24px', height: '24px', color: '#7c3aed', marginBottom: '12px' }} />
            <h3 style={{ fontSize: '16px', fontWeight: 800, margin: '0 0 6px' }}>WebRTC P2P Calls</h3>
            <p style={{ fontSize: '13px', color: '#64748b', margin: 0, lineHeight: 1.5 }}>
              Direct peer-to-peer media tunnels mean zero server relay recording or eavesdropping on your private voice/video calls.
            </p>
          </div>

          <div style={{ backgroundColor: '#f8fafc', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <EyeOff style={{ width: '24px', height: '24px', color: '#059669', marginBottom: '12px' }} />
            <h3 style={{ fontSize: '16px', fontWeight: 800, margin: '0 0 6px' }}>Ghost Mode</h3>
            <p style={{ fontSize: '13px', color: '#64748b', margin: 0, lineHeight: 1.5 }}>
              Enforces 30s auto-disappearing messages, view-once media items, screenshot block overlays, and biometrics.
            </p>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};
