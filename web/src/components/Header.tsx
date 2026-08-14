import React from 'react';
import { Download } from 'lucide-react';
import logoImg from '../assets/logo.png';

export const Header: React.FC = () => {
  return (
    <header
      style={{
        borderBottom: '1px solid #f1f5f9',
        backgroundColor: 'rgba(255, 255, 255, 0.98)',
        backdropFilter: 'blur(20px)',
        position: 'sticky',
        top: 0,
        zIndex: 50,
        padding: '14px 32px',
        boxShadow: '0 2px 10px rgba(0, 0, 0, 0.02)',
      }}
    >
      <div
        style={{
          width: '100%',
          margin: '0 auto',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        {/* Brand Official Transparent Logo Image */}
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', textDecoration: 'none' }}>
            <img
              src={logoImg}
              alt="OurSpace - A Private Space For Two"
              style={{ height: '44px', width: 'auto', display: 'block', objectFit: 'contain' }}
            />
          </a>
        </div>

        {/* Right-Aligned Desktop & Mobile Nav Links */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '24px', marginLeft: 'auto', flexWrap: 'wrap' }}>
          <a href="/" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Home</a>
          <a href="/about" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>About Us</a>
          <a href="/contact" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Contact Us</a>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.2)', color: '#059669', fontSize: '12px', fontWeight: 700 }}>
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block' }} />
            <span>E2EE Active</span>
          </div>

          <button
            onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play Store.')}
            style={{
              fontSize: '14px',
              fontWeight: 'bold',
              padding: '10px 20px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 50%, #2563eb 100%)',
              color: '#ffffff',
              border: 'none',
              cursor: 'pointer',
              boxShadow: '0 6px 20px rgba(217, 70, 239, 0.25)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
            }}
          >
            <Download style={{ width: '16px', height: '16px' }} />
            <span>Get Mobile App</span>
          </button>
        </div>
      </div>
    </header>
  );
};
