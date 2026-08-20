import React from 'react';

export const Footer: React.FC = () => {
  return (
    <footer className="site-footer">
      <div className="footer-inner">
        <div>
          <p style={{ margin: 0, fontWeight: 600, color: '#475569', fontSize: '13px' }}>
            © 2026 OurSpace Privacy Chat. All rights reserved.
          </p>
        </div>

        <div className="footer-links">
          <a
            href="/privacy"
            style={{ color: '#475569', textDecoration: 'none', fontWeight: 600, transition: 'color 0.2s ease' }}
            onMouseEnter={(e) => (e.currentTarget.style.color = '#c026d3')}
            onMouseLeave={(e) => (e.currentTarget.style.color = '#475569')}
          >
            Privacy Policy
          </a>
          <span style={{ color: '#cbd5e1' }}>•</span>
          <a
            href="/terms"
            style={{ color: '#475569', textDecoration: 'none', fontWeight: 600, transition: 'color 0.2s ease' }}
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
