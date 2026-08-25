import React, { useState } from 'react';
import { Download, ShieldCheck, X, Menu } from 'lucide-react';
import logoImg from '../assets/logo.png';

export const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <>
      <header className="site-header">
        <div className="header-inner">
          {/* Logo */}
          <div className="header-logo">
            <a href="/" aria-label="OurSpace Home" className="flex items-center">
              <img src={logoImg} alt="OurSpace" style={{ height: '42px', width: 'auto', objectFit: 'contain' }} />
            </a>
          </div>

          {/* Desktop Nav */}
          <nav className="header-nav">
            <a href="/" className="header-nav-link">Home</a>
            <a href="/about" className="header-nav-link">About Us</a>
            <a href="/contact" className="header-nav-link">Contact Us</a>
          </nav>

          <div className="header-actions">
            {/* E2EE Badge — hidden on small mobile */}
            <div className="header-badge hide-mobile">
              <ShieldCheck style={{ width: '15px', height: '15px', color: '#10b981' }} />
              <span>E2EE Active</span>
            </div>

            {/* CTA Button */}
            <a
              href="https://play.google.com/store/apps/details?id=com.ourspace.app"
              target="_blank"
              rel="noopener noreferrer"
              className="header-cta"
            >
              <Download style={{ width: '16px', height: '16px', flexShrink: 0 }} />
              <span>Get App</span>
            </a>

            {/* Hamburger — shown on mobile */}
            <button
              className="hamburger"
              onClick={() => setMenuOpen(true)}
              aria-label="Open menu"
            >
              <span />
              <span />
              <span />
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Full-Screen Menu */}
      <div className={`mobile-menu ${menuOpen ? 'open' : ''}`} role="dialog" aria-modal="true">
        <button className="mobile-menu-close" onClick={() => setMenuOpen(false)} aria-label="Close menu">
          <X size={28} color="#475569" />
        </button>

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '32px' }}>
          <img src={logoImg} alt="OurSpace" style={{ height: '56px', marginBottom: '8px' }} />

          <a href="/" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Home</a>
          <a href="/about" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>About Us</a>
          <a href="/contact" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Contact Us</a>
          <a href="/privacy" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Privacy Policy</a>
          <a href="/terms" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Terms & Conditions</a>

          <a
            href="https://play.google.com/store/apps/details?id=com.ourspace.app"
            target="_blank"
            rel="noopener noreferrer"
            className="header-cta"
            style={{ fontSize: '16px', padding: '14px 28px', borderRadius: '14px' }}
            onClick={() => setMenuOpen(false)}
          >
            <Download style={{ width: '18px', height: '18px' }} />
            <span>Download App</span>
          </a>
        </div>
      </div>
    </>
  );
};
