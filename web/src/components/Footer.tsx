import React from 'react';

export const Footer: React.FC = () => {
  return (
    <footer
      style={{
        borderTop: '1px solid #e2e8f0',
        backgroundColor: '#ffffff',
        padding: '36px 24px',
        fontSize: '13px',
        color: '#64748b',
        zIndex: 10,
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
        <div>
          <p style={{ margin: 0, fontWeight: 600, color: '#475569', fontSize: '13px' }}>
            © 2026 OurSpace Privacy Chat. All rights reserved.
          </p>
        </div>

        {/* Footer Nav Links: Privacy Policy & Terms & Conditions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px', flexWrap: 'wrap' }}>
          <a
            href="/privacy"
            style={{
              color: '#475569',
              textDecoration: 'none',
              fontWeight: 600,
              transition: 'color 0.2s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
            onMouseLeave={(e) => (e.currentTarget.style.color = '#475569')}
          >
            Privacy Policy
          </a>
          <span style={{ color: '#cbd5e1' }}>•</span>
          <a
            href="/terms"
            style={{
              color: '#475569',
              textDecoration: 'none',
              fontWeight: 600,
              transition: 'color 0.2s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
            onMouseLeave={(e) => (e.currentTarget.style.color = '#475569')}
          >
            Terms & Conditions
          </a>
          <span style={{ color: '#cbd5e1' }}>•</span>
          <span style={{ color: '#c026d3', fontWeight: 700, letterSpacing: '0.02em' }}>
            A Private Space For Two
          </span>
        </div>
      </div>
    </footer>
  );
};
