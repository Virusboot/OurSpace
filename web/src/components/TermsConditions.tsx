import React from 'react';
import { Shield } from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

export const TermsConditions: React.FC = () => {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff', color: '#0f172a', fontFamily: "'Inter', sans-serif", display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
      <Header />

      {/* Main Content */}
      <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '48px 32px', textAlign: 'left', flex: 1, width: '100%', boxSizing: 'border-box' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.08)', color: '#c026d3', fontSize: '12px', fontWeight: 800, marginBottom: '16px' }}>
          <Shield style={{ width: '14px', height: '14px' }} />
          <span>Google Play Store Terms of Service</span>
        </div>

        <h1 style={{ fontSize: '36px', fontWeight: 900, marginBottom: '8px', color: '#0f172a' }}>Terms & Conditions</h1>
        <p style={{ color: '#64748b', fontSize: '14px', marginBottom: '32px' }}>Last Updated: August 14, 2026 | App Version 1.0.0</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '28px', lineHeight: 1.7, color: '#334155', fontSize: '15px' }}>
          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>1. Acceptance of Terms</h2>
            <p style={{ margin: 0 }}>
              By downloading, accessing, or using the OurSpace mobile application or web services, you agree to be bound by these Terms and Conditions.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>2. Acceptable Use & Conduct</h2>
            <p style={{ margin: 0 }}>
              You agree to use OurSpace solely for lawful, private communications. You must not use the platform to transmit unlawful content, engage in harassment, or attempt to compromise the network integrity.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>3. Cryptographic Security Responsibility</h2>
            <p style={{ margin: 0 }}>
              Because OurSpace is a Zero-Knowledge End-to-End Encrypted platform, your private keys reside solely on your device. You are responsible for preserving your app PIN and local backup keys. OurSpace staff cannot recover lost private keys or decrypt past messages.
            </p>
          </section>

          <section>
            <h2 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginBottom: '10px' }}>4. Disclaimer & Service Availability</h2>
            <p style={{ margin: 0 }}>
              OurSpace is provided "AS IS" without warranties of any kind. We continuously maintain WebRTC relay nodes to optimize call connectivity.
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
};
