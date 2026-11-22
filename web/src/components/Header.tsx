import React, { useEffect, useState } from 'react';
import { Download, ShieldCheck, X, Menu, User, LogIn, LogOut } from 'lucide-react';
import logoImg from '../assets/logo.png';

export const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState<any>(null);

  useEffect(() => {
    try {
      const stored = localStorage.getItem('ws_user') || sessionStorage.getItem('ws_user');
      if (stored) {
        setCurrentUser(JSON.parse(stored));
      }
    } catch (_) {}
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('ws_token');
    localStorage.removeItem('ws_user');
    sessionStorage.removeItem('ws_token');
    sessionStorage.removeItem('ws_user');
    window.location.href = '/login';
  };

  const displayName = currentUser?.name || currentUser?.username?.replace(/^@/, '') || 'My Profile';
  const userInitial = displayName.charAt(0).toUpperCase();

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
            {currentUser && (
              <a href="/profile" className="header-nav-link" style={{ color: '#7B2FBE', fontWeight: 700 }}>
                Profile
              </a>
            )}
            <a href="/about" className="header-nav-link">About Us</a>
            <a href="/contact" className="header-nav-link">Contact Us</a>
          </nav>

          <div className="header-actions">
            {/* E2EE Badge — hidden on small mobile */}
            <div className="header-badge hide-mobile">
              <ShieldCheck style={{ width: '15px', height: '15px', color: '#10b981' }} />
              <span>E2EE Active</span>
            </div>

            {/* Profile Pill if Logged In / Sign In Button if Logged Out */}
            {currentUser ? (
              <a
                href="/profile"
                className="hide-mobile"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '6px 14px',
                  borderRadius: '16px',
                  backgroundColor: 'rgba(123,47,190,0.08)',
                  border: '1px solid rgba(123,47,190,0.25)',
                  textDecoration: 'none',
                  color: '#0F172A',
                  fontSize: '13px',
                  fontWeight: 700,
                  transition: 'all 0.2s'
                }}
              >
                <div style={{
                  width: '24px',
                  height: '24px',
                  borderRadius: '50%',
                  background: 'linear-gradient(135deg,#7B2FBE 0%,#E91E8C 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#fff',
                  fontSize: '11px',
                  fontWeight: 800,
                  overflow: 'hidden'
                }}>
                  {currentUser.profileImage ? (
                    <img src={currentUser.profileImage} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    userInitial
                  )}
                </div>
                <span>{displayName}</span>
              </a>
            ) : (
              <a
                href="/login"
                className="hide-mobile"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '7px 14px',
                  borderRadius: '14px',
                  backgroundColor: '#F1F5F9',
                  border: '1px solid #CBD5E1',
                  textDecoration: 'none',
                  color: '#475569',
                  fontSize: '13px',
                  fontWeight: 600,
                  transition: 'all 0.2s'
                }}
              >
                <LogIn size={14} color="#7B2FBE" />
                <span>Sign In</span>
              </a>
            )}

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

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '24px' }}>
          <img src={logoImg} alt="OurSpace" style={{ height: '52px', marginBottom: '8px' }} />

          {currentUser && (
            <a
              href="/profile"
              className="mobile-menu-link"
              style={{
                color: '#7B2FBE',
                fontWeight: 800,
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 20px',
                borderRadius: '16px',
                backgroundColor: 'rgba(123,47,190,0.08)'
              }}
              onClick={() => setMenuOpen(false)}
            >
              <User size={18} />
              <span>My Profile ({displayName})</span>
            </a>
          )}

          <a href="/" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Home</a>
          <a href="/about" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>About Us</a>
          <a href="/contact" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Contact Us</a>
          <a href="/privacy" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Privacy Policy</a>
          <a href="/terms" className="mobile-menu-link" onClick={() => setMenuOpen(false)}>Terms & Conditions</a>

          {currentUser ? (
            <button
              onClick={() => { setMenuOpen(false); handleLogout(); }}
              style={{
                background: 'none',
                border: 'none',
                color: '#E11D48',
                fontSize: '16px',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                cursor: 'pointer'
              }}
            >
              <LogOut size={16} />
              <span>Log Out</span>
            </button>
          ) : (
            <a
              href="/login"
              className="mobile-menu-link"
              style={{ color: '#7B2FBE', fontWeight: 700 }}
              onClick={() => setMenuOpen(false)}
            >
              Sign In to Account
            </a>
          )}

          <a
            href="https://play.google.com/store/apps/details?id=com.ourspace.app"
            target="_blank"
            rel="noopener noreferrer"
            className="header-cta"
            style={{ fontSize: '15px', padding: '12px 24px', borderRadius: '14px', marginTop: '8px' }}
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
