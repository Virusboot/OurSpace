import React from 'react';
import logoImg from '../assets/logo.png';

export const Footer: React.FC = () => {
  return (
    <footer
      style={{
        borderTop: '1px solid #e2e8f0',
        backgroundColor: '#f8fafc',
        padding: '32px 40px',
        textAlign: 'center',
        fontSize: '13px',
        color: '#64748b',
        zIndex: 1,
      }}
    >
      <div
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '20px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <img src={logoImg} alt="OurSpace Logo" style={{ height: '36px', width: 'auto', display: 'block', objectFit: 'contain' }} />
          <p style={{ margin: 0, fontWeight: 600, color: '#475569' }}>© 2026 OurSpace Privacy Chat. All rights reserved.</p>
        </div>

        {/* Footer Nav Links: Privacy Policy & Terms & Conditions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px', flexWrap: 'wrap' }}>
          <a href="/privacy" style={{ color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Privacy Policy</a>
          <span>•</span>
          <a href="/terms" style={{ color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Terms & Conditions</a>
          <span>•</span>
          <span style={{ color: '#c026d3', fontWeight: 700 }}>A Private Space For Two</span>
        </div>
      </div>
    </footer>
  );
};
