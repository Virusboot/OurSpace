import React, { useState } from 'react';
import { Mail, Send, CheckCircle2 } from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

export const ContactUs: React.FC = () => {
  const [submitted, setSubmitted] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !message) return;
    setSubmitted(true);
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#ffffff', color: '#0f172a', fontFamily: "'Inter', sans-serif", display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
      <Header />

      {/* Main Content */}
      <main style={{ maxWidth: '1280px', margin: '0 auto', padding: '48px 32px', textAlign: 'left', flex: 1, width: '100%', boxSizing: 'border-box' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '6px 14px', borderRadius: '20px', backgroundColor: 'rgba(217, 70, 239, 0.08)', color: '#c026d3', fontSize: '12px', fontWeight: 800, marginBottom: '16px' }}>
          <Mail style={{ width: '14px', height: '14px' }} />
          <span>Support & Inquiries</span>
        </div>

        <h1 style={{ fontSize: '36px', fontWeight: 900, marginBottom: '8px', color: '#0f172a' }}>Contact Us</h1>
        <p style={{ color: '#64748b', fontSize: '15px', marginBottom: '32px' }}>
          Have questions, security feedback, or need support? Our team is here to assist you 24/7.
        </p>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '24px', padding: '32px', boxShadow: '0 15px 35px rgba(0,0,0,0.03)' }}>
          {submitted ? (
            <div style={{ textAlign: 'center', padding: '32px 16px' }}>
              <div style={{ width: '56px', height: '56px', borderRadius: '50%', backgroundColor: 'rgba(16, 185, 129, 0.1)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: '#10b981', marginBottom: '16px' }}>
                <CheckCircle2 style={{ width: '32px', height: '32px' }} />
              </div>
              <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#0f172a', marginBottom: '8px' }}>Message Received!</h3>
              <p style={{ color: '#64748b', fontSize: '14px', margin: 0 }}>
                Thank you for reaching out to OurSpace Support. We will get back to your email shortly.
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 800, color: '#475569', marginBottom: '8px' }}>Your Name</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter your name"
                  style={{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px 14px', fontSize: '14px', color: '#0f172a', outline: 'none', boxSizing: 'border-box' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 800, color: '#475569', marginBottom: '8px' }}>Email Address</label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@example.com"
                  style={{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px 14px', fontSize: '14px', color: '#0f172a', outline: 'none', boxSizing: 'border-box' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 800, color: '#475569', marginBottom: '8px' }}>Message / Inquiry</label>
                <textarea
                  required
                  rows={5}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="How can we help you?"
                  style={{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #cbd5e1', borderRadius: '12px', padding: '12px 14px', fontSize: '14px', color: '#0f172a', outline: 'none', resize: 'none', boxSizing: 'border-box' }}
                />
              </div>

              <button
                type="submit"
                style={{
                  background: 'linear-gradient(135deg, #d946ef 0%, #8b5cf6 100%)',
                  color: '#ffffff',
                  fontWeight: 'bold',
                  fontSize: '15px',
                  padding: '14px',
                  borderRadius: '12px',
                  border: 'none',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  boxShadow: '0 6px 20px rgba(217, 70, 239, 0.3)',
                }}
              >
                <Send style={{ width: '16px', height: '16px' }} />
                <span>Send Message</span>
              </button>
            </form>
          )}

          <div style={{ marginTop: '32px', paddingTop: '24px', borderTop: '1px solid #f1f5f9', display: 'flex', gap: '24px', justifyContent: 'center', fontSize: '13px', color: '#64748b' }}>
            <span><strong>Email:</strong> support@ourspace.app</span>
            <span>•</span>
            <span><strong>Response Time:</strong> Within 2 hours</span>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};
