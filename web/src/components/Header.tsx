import React, { useState } from 'react';
import { Download, Menu, X, Shield } from 'lucide-react';
import logoImg from '../assets/logo.png';

export const Header: React.FC = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header
      style={{
        borderBottom: '1px solid #f1f5f9',
        backgroundColor: 'rgba(255, 255, 255, 0.98)',
        backdropFilter: 'blur(20px)',
        position: 'sticky',
        top: 0,
        zIndex: 50,
        padding: '14px 40px',
        boxShadow: '0 2px 10px rgba(0, 0, 0, 0.02)',
      }}
    >
      <div
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {/* Brand Official Logo Image */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', textDecoration: 'none' }}>
            <img
              src={logoImg}
              alt="OurSpace - A Private Space For Two"
              style={{ height: '48px', width: 'auto', display: 'block', objectFit: 'contain' }}
            />
          </a>
          <span
            style={{
              fontSize: '11px',
              padding: '4px 12px',
              borderRadius: '9999px',
              backgroundColor: 'rgba(217, 70, 239, 0.08)',
              border: '1px solid rgba(217, 70, 239, 0.2)',
              color: '#c026d3',
              fontWeight: 800,
              letterSpacing: '0.04em',
            }}
            className="hidden md:inline-block"
          >
            ZERO KNOWLEDGE E2EE
          </span>
        </div>

        {/* Desktop Nav Links */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }} className="hidden lg:flex">
          <a href="/" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Home</a>
          <a href="/about" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>About Us</a>
          <a href="/privacy" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Privacy Policy</a>
          <a href="/terms" style={{ fontSize: '14px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Terms & Conditions</a>
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

        {/* Mobile Hamburger Toggle */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          style={{
            display: 'flex',
            background: 'none',
            border: '1px solid #e2e8f0',
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
            borderTop: '1px solid #f1f5f9',
            display: 'flex',
            flexDirection: 'column',
            gap: '16px',
            backgroundColor: '#ffffff',
          }}
        >
          <a href="/" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Home</a>
          <a href="/about" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>About Us</a>
          <a href="/privacy" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Privacy Policy</a>
          <a href="/terms" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Terms & Conditions</a>
          <a href="/contact" onClick={() => setMobileMenuOpen(false)} style={{ fontSize: '15px', color: '#475569', textDecoration: 'none', fontWeight: 600 }}>Contact Us</a>
          <button
            onClick={() => alert('OurSpace Mobile App (v1.0.0) is available on Google Play Store.')}
            style={{
              fontSize: '15px',
              fontWeight: 'bold',
              padding: '14px',
              borderRadius: '12px',
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
  );
};
