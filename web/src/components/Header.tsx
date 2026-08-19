import React from 'react';
import { Download, ShieldCheck } from 'lucide-react';
import logoImg from '../assets/logo.png';

export const Header: React.FC = () => {
  return (
    <header
      style={{
        borderBottom: '1px solid #e2e8f0',
        backgroundColor: 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        position: 'sticky',
        top: 0,
        zIndex: 100,
        padding: '16px 24px',
        boxShadow: '0 4px 20px rgba(15, 23, 42, 0.03)',
      }}
    >
      <div
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '20px',
        }}
      >
        {/* Brand Official Transparent Logo Image */}
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', textDecoration: 'none', transition: 'opacity 0.2s' }}>
            <img
              src={logoImg}
              alt="OurSpace - A Private Space For Two"
              style={{ height: '52px', width: 'auto', display: 'block', objectFit: 'contain' }}
            />
          </a>
        </div>

        {/* Right-Aligned Professional Nav Links & Action Button */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '28px', flexWrap: 'wrap' }}>
          <nav style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
            <a
              href="/"
              style={{
                fontSize: '14px',
                fontWeight: 600,
                color: '#334155',
                textDecoration: 'none',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#334155')}
            >
              Home
            </a>
            <a
              href="/about"
              style={{
                fontSize: '14px',
                fontWeight: 600,
                color: '#334155',
                textDecoration: 'none',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#334155')}
            >
              About Us
            </a>
            <a
              href="/contact"
              style={{
                fontSize: '14px',
                fontWeight: '600',
                color: '#334155',
                textDecoration: 'none',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#334155')}
            >
              Contact Us
            </a>
          </nav>
          
          {/* E2EE Active Security Badge */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 14px',
              borderRadius: '9999px',
              backgroundColor: '#ecfdf5',
              border: '1px solid rgba(16, 185, 129, 0.25)',
              color: '#059669',
              fontSize: '12px',
              fontWeight: 700,
              letterSpacing: '0.01em',
            }}
          >
            <ShieldCheck style={{ width: '15px', height: '15px', color: '#10b981' }} />
            <span>E2EE Active</span>
          </div>

          {/* Primary Gradient Action Button */}
          <a
            href="https://play.google.com/store/apps/details?id=com.ourspace.app"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              fontSize: '14px',
              fontWeight: 700,
              padding: '10px 22px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #c026d3 0%, #7c3aed 100%)',
              color: '#ffffff',
              border: 'none',
              cursor: 'pointer',
              boxShadow: '0 4px 14px rgba(192, 38, 211, 0.3)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              transition: 'transform 0.2s ease, box-shadow 0.2s ease',
              textDecoration: 'none',
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLAnchorElement).style.transform = 'translateY(-1px)';
              (e.currentTarget as HTMLAnchorElement).style.boxShadow = '0 6px 20px rgba(192, 38, 211, 0.4)';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLAnchorElement).style.transform = 'translateY(0)';
              (e.currentTarget as HTMLAnchorElement).style.boxShadow = '0 4px 14px rgba(192, 38, 211, 0.3)';
            }}
          >
            <Download style={{ width: '16px', height: '16px' }} />
            <span>Get Mobile App</span>
          </a>
        </div>
      </div>
    </header>
  );
};
