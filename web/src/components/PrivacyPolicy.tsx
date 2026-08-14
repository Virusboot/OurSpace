import React from 'react';
import { Shield, Lock, CheckCircle2 } from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

export const PrivacyPolicy: React.FC = () => {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff', color: '#0f172a', fontFamily: "'Inter', sans-serif", display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
      <Header />

      {/* Main Content */}
      <main style={{ maxWidth: '900px', margin: '0 auto', padding: '48px 24px', textAlign: 'left' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.08)', color: '#c026d3', fontSize: '12px', fontWeight: 800, marginBottom: '16px' }}>
          <Shield style={{ width: '14px', height: '14px' }} />
          <span>Google Play Store Compliant Privacy Policy</span>
        </div>

        <h1 style={{ fontSize: '36px', fontWeight: 900, marginBottom: '8px', color: '#0f172a' }}>Privacy Policy</h1>
        <p style={{ color: '#64748b', fontSize: '14px', marginBottom: '32px' }}>Effective Date: August 14, 2026 | App Version 1.0.0</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '28px', lineHeight: 1.7, color: '#334155', fontSize: '15px' }}>
          <section style={{ backgroundColor: '#f8fafc', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>1. Zero-Knowledge Architecture & Data Collection</h2>
            <p style={{ margin: 0 }}>
              OurSpace is built on a strict Zero-Knowledge End-to-End Encryption (E2EE) architecture. We do <strong>NOT</strong> collect, store, track, sell, or share your personal data, phone numbers, email addresses, contact lists, or location data.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>2. End-to-End Encryption (E2EE)</h2>
            <p style={{ margin: 0 }}>
              All chat messages, voice calls, and video streams are encrypted directly on your device using <strong>AES-256-GCM symmetric encryption</strong> and <strong>ECDH Curve25519 key exchange</strong>. Decryption keys reside exclusively on your local device. Our servers cannot read your communications or access your private call content.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>3. Peer-to-Peer WebRTC Calls</h2>
            <p style={{ margin: 0 }}>
              Audio and video calls are established using direct Peer-to-Peer (P2P) WebRTC connections. Call data streams flow directly between participants with zero relay recording or server-side media storage.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>4. Device Permissions</h2>
            <p>OurSpace requests minimal Android and Web browser permissions exclusively for essential app functionality:</p>
            <ul style={{ paddingLeft: '20px', margin: '8px 0 0' }}>
              <li><strong>Camera:</strong> Required for HD video calls and view-once photo capture.</li>
              <li><strong>Microphone:</strong> Required for crystal-clear WebRTC audio calls and voice notes.</li>
              <li><strong>Biometrics:</strong> Optional local device authentication (Fingerprint / Face Unlock).</li>
            </ul>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>5. Contact Information & Support</h2>
            <p style={{ margin: 0 }}>
              If you have any questions or inquiries regarding our Privacy Policy or security practices, please contact our support team at <a href="mailto:support@ourspace.app" style={{ color: '#c026d3', fontWeight: 700 }}>support@ourspace.app</a>.
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
};
