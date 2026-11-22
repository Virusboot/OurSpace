import React, { useEffect, useState } from 'react';
import {
  User, Shield, ShieldCheck, Copy, Check, Edit3, Camera,
  LogOut, ArrowLeft, Mail, Lock, Phone, AlertTriangle, Save,
  X, Trash2, Zap, RefreshCw, Key
} from 'lucide-react';
import { Header } from './Header';
import { Footer } from './Footer';

interface UserData {
  id: string;
  username: string;
  name?: string;
  bio?: string;
  profileImage?: string;
  email?: string;
  privateId?: string;
  publicKey?: string;
}

export const WebProfile: React.FC = () => {
  const [user, setUser] = useState<UserData | null>(() => {
    try {
      const stored = localStorage.getItem('ws_user') || sessionStorage.getItem('ws_user');
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState<string | null>(() => {
    return localStorage.getItem('ws_token') || sessionStorage.getItem('ws_token');
  });

  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [copiedId, setCopiedId] = useState(false);
  const [copiedKey, setCopiedKey] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Edit Modal State
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [editUsername, setEditUsername] = useState('');
  const [editBio, setEditBio] = useState('');
  const [editImage, setEditImage] = useState<string>('');
  const [saving, setSaving] = useState(false);

  // Delete Modal State
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const fetchFreshProfile = async (authToken?: string) => {
    const activeToken = authToken || token;
    if (!activeToken) return;
    try {
      setRefreshing(true);
      setErrorMsg(null);
      const res = await fetch('/api/users/me', {
        headers: {
          'Authorization': `Bearer ${activeToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (!res.ok) {
        if (res.status === 401 || res.status === 404) {
          handleLogout();
          return;
        }
        throw new Error('Failed to refresh profile from database');
      }

      const freshUser: UserData = await res.json();
      setUser((prev) => {
        const merged = { ...prev, ...freshUser };
        localStorage.setItem('ws_user', JSON.stringify(merged));
        sessionStorage.setItem('ws_user', JSON.stringify(merged));
        return merged;
      });
    } catch (err: any) {
      console.warn('Profile refresh notice:', err.message);
    } finally {
      setRefreshing(false);
      setLoading(false);
    }
  };

  useEffect(() => {
    // If not logged in, wait briefly before showing empty state
    if (!token && !user) {
      const storedToken = localStorage.getItem('ws_token') || sessionStorage.getItem('ws_token');
      const storedUser = localStorage.getItem('ws_user') || sessionStorage.getItem('ws_user');
      if (storedToken) {
        setToken(storedToken);
        if (storedUser) {
          try { setUser(JSON.parse(storedUser)); } catch {}
        }
        fetchFreshProfile(storedToken);
      }
      return;
    }

    // Refresh fresh profile data from database on page load / refresh
    fetchFreshProfile();
  }, []);

  const handleCopy = (text: string, type: 'id' | 'key') => {
    navigator.clipboard.writeText(text);
    if (type === 'id') {
      setCopiedId(true);
      setTimeout(() => setCopiedId(false), 2000);
    } else {
      setCopiedKey(true);
      setTimeout(() => setCopiedKey(false), 2000);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('ws_token');
    localStorage.removeItem('ws_user');
    sessionStorage.removeItem('ws_token');
    sessionStorage.removeItem('ws_user');
    window.location.href = '/login';
  };

  const openEditModal = () => {
    if (!user) return;
    setEditName(user.name || user.username.replace('@', ''));
    setEditUsername(user.username.replace(/^@/, ''));
    setEditBio(user.bio || '');
    setEditImage(user.profileImage || '');
    setIsEditOpen(true);
  };

  const handleImagePick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
      alert('Profile picture must be under 2MB');
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const base64 = event.target?.result as string;
      setEditImage(base64);
    };
    reader.readAsDataURL(file);
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setSaving(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    const formattedUsername = editUsername.trim().startsWith('@') 
      ? editUsername.trim() 
      : `@${editUsername.trim().toLowerCase()}`;

    try {
      const res = await fetch('/api/users/profile', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: editName.trim(),
          username: formattedUsername,
          bio: editBio.trim(),
          profileImage: editImage
        })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to update profile');

      const updatedUser: UserData = {
        ...user,
        ...data.user,
        name: editName.trim(),
        username: formattedUsername,
        bio: editBio.trim(),
        profileImage: editImage
      };

      if (data.token) {
        localStorage.setItem('ws_token', data.token);
        sessionStorage.setItem('ws_token', data.token);
        setToken(data.token);
      }

      localStorage.setItem('ws_user', JSON.stringify(updatedUser));
      sessionStorage.setItem('ws_user', JSON.stringify(updatedUser));
      setUser(updatedUser);

      setIsEditOpen(false);
      setSuccessMsg('Profile updated and synchronized successfully!');
      setTimeout(() => setSuccessMsg(null), 4000);
    } catch (err: any) {
      setErrorMsg(err.message || 'Error updating profile');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteAccount = async () => {
    if (!token) return;
    setDeleting(true);
    try {
      const res = await fetch('/api/users/me', {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || 'Failed to delete account');
      }
      handleLogout();
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to delete account');
      setIsDeleteOpen(false);
      setDeleting(false);
    }
  };

  // If not logged in and not loading, show clean Login CTA
  if (!user && !loading && !refreshing) {
    return (
      <div className="min-h-screen flex flex-col bg-[#F8FAFC]">
        <Header />
        <main className="flex-1 flex items-center justify-center p-6">
          <div className="max-w-md w-full bg-white rounded-3xl p-8 border border-slate-200 shadow-xl text-center">
            <div className="w-16 h-16 rounded-2xl bg-purple-100 flex items-center justify-center mx-auto mb-4">
              <User className="w-8 h-8 text-[#7B2FBE]" />
            </div>
            <h2 className="text-2xl font-bold font-heading text-slate-900 mb-2">No Active Profile Found</h2>
            <p className="text-sm text-slate-500 mb-6">
              Please sign in to view your profile, manage end-to-end encrypted settings, and sync your identity.
            </p>
            <a
              href="/login?return=/profile"
              className="inline-flex items-center justify-center w-full py-3.5 px-6 rounded-xl bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white font-semibold shadow-lg shadow-purple-500/25 hover:opacity-95 transition"
            >
              Sign In to Your Account
            </a>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  const displayName = user?.name || (user?.username ? user.username.replace(/^@/, '') : 'User');
  const userHandle = user?.username ? (user.username.startsWith('@') ? user.username : `@${user.username}`) : '@anonymous';
  const privateId = user?.privateId || (user?.id ? `USER-${user.id.substring(0, 6).toUpperCase()}` : 'USER-UNKNOWN');
  const bioText = user?.bio || 'Available | End-to-End Encrypted Space';
  const userInitial = displayName.charAt(0).toUpperCase();

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#F8FAFC', display: 'flex', flexDirection: 'column' }}>
      <Header />

      <main className="main-content" style={{ flex: 1, padding: '32px 16px 64px', maxWidth: '840px', margin: '0 auto', width: '100%' }}>
        {/* Top Breadcrumb & Status */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
          <a
            href="/"
            style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', color: '#64748B', fontSize: '13px', fontWeight: 600, textDecoration: 'none' }}
          >
            <ArrowLeft size={16} />
            <span>Back to Home</span>
          </a>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <button
              onClick={() => fetchFreshProfile()}
              disabled={refreshing}
              title="Refresh profile from database"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '6px 12px',
                borderRadius: '12px',
                backgroundColor: '#ffffff',
                border: '1px solid #E2E8F0',
                color: '#64748B',
                fontSize: '12px',
                fontWeight: 600,
                cursor: refreshing ? 'not-allowed' : 'pointer'
              }}
            >
              <RefreshCw size={13} className={refreshing ? 'animate-spin text-[#7B2FBE]' : ''} />
              <span>{refreshing ? 'Syncing...' : 'Sync Profile'}</span>
            </button>

            <button
              onClick={handleLogout}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '6px 12px',
                borderRadius: '12px',
                backgroundColor: '#FFF1F2',
                border: '1px solid #FECDD3',
                color: '#E11D48',
                fontSize: '12px',
                fontWeight: 600,
                cursor: 'pointer'
              }}
            >
              <LogOut size={13} />
              <span>Log Out</span>
            </button>
          </div>
        </div>

        {/* Alerts */}
        {successMsg && (
          <div style={{ padding: '12px 16px', borderRadius: '16px', backgroundColor: '#ECFDF5', border: '1px solid #A7F3D0', color: '#065F46', fontSize: '13px', fontWeight: 600, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ShieldCheck size={18} color="#10B981" />
            <span>{successMsg}</span>
          </div>
        )}

        {errorMsg && (
          <div style={{ padding: '12px 16px', borderRadius: '16px', backgroundColor: '#FFF1F2', border: '1px solid #FECDD3', color: '#9F1239', fontSize: '13px', fontWeight: 600, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertTriangle size={18} color="#E11D48" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* ── PROFILE HERO CARD ── */}
        <div style={{
          backgroundColor: '#ffffff',
          borderRadius: '28px',
          border: '1px solid #E2E8F0',
          boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
          overflow: 'hidden',
          marginBottom: '24px'
        }}>
          {/* Card Top Banner with Gradient */}
          <div style={{
            height: '110px',
            background: 'linear-gradient(135deg, rgba(123,47,190,0.85) 0%, rgba(233,30,140,0.85) 100%)',
            position: 'relative'
          }}>
            <div style={{ position: 'absolute', right: '20px', top: '16px', display: 'flex', gap: '8px' }}>
              <div style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '4px 10px',
                borderRadius: '20px',
                backgroundColor: 'rgba(255,255,255,0.2)',
                backdropFilter: 'blur(8px)',
                color: '#ffffff',
                fontSize: '11px',
                fontWeight: 700,
                letterSpacing: '0.04em'
              }}>
                <ShieldCheck size={13} />
                <span>E2EE Cryptographic Identity</span>
              </div>
            </div>
          </div>

          {/* Profile Header Content */}
          <div style={{ padding: '0 28px 28px', marginTop: '-55px', position: 'relative' }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'flex-end', justifyContent: 'space-between', gap: '16px' }}>
              
              {/* Avatar */}
              <div style={{ position: 'relative' }}>
                <div style={{
                  width: '108px',
                  height: '108px',
                  borderRadius: '50%',
                  padding: '4px',
                  background: 'linear-gradient(135deg, #7B2FBE 0%, #E91E8C 100%)',
                  boxShadow: '0 8px 24px rgba(123,47,190,0.3)',
                  backgroundColor: '#ffffff'
                }}>
                  <div style={{
                    width: '100%',
                    height: '100%',
                    borderRadius: '50%',
                    overflow: 'hidden',
                    backgroundColor: '#F1F5F9',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    {user?.profileImage ? (
                      <img
                        src={user.profileImage}
                        alt={displayName}
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />
                    ) : (
                      <span style={{ fontSize: '42px', fontWeight: 800, color: '#7B2FBE', fontFamily: 'Outfit, sans-serif' }}>
                        {userInitial}
                      </span>
                    )}
                  </div>
                </div>

                {/* Edit Photo Icon Button */}
                <button
                  onClick={openEditModal}
                  title="Change Profile Photo"
                  style={{
                    position: 'absolute',
                    bottom: '4px',
                    right: '4px',
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#7B2FBE',
                    color: '#ffffff',
                    border: '2.5px solid #ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    boxShadow: '0 4px 10px rgba(0,0,0,0.15)'
                  }}
                >
                  <Camera size={14} />
                </button>
              </div>

              {/* Edit Profile Button */}
              <button
                onClick={openEditModal}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '10px 20px',
                  borderRadius: '14px',
                  backgroundColor: '#F8FAFC',
                  border: '1.5px solid #CBD5E1',
                  color: '#0F172A',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  boxShadow: '0 2px 6px rgba(0,0,0,0.03)'
                }}
              >
                <Edit3 size={15} color="#7B2FBE" />
                <span>Edit Profile</span>
              </button>
            </div>

            {/* Names & Handle */}
            <div style={{ marginTop: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                <h1 style={{ fontSize: '26px', fontWeight: 800, color: '#0F172A', margin: 0, fontFamily: 'Outfit, sans-serif' }}>
                  {displayName}
                </h1>
                <span style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  padding: '3px 10px',
                  borderRadius: '20px',
                  backgroundColor: 'rgba(123,47,190,0.08)',
                  color: '#7B2FBE',
                  fontSize: '13px',
                  fontWeight: 700
                }}>
                  {userHandle}
                </span>
              </div>

              {/* Bio Bubble */}
              <div style={{
                marginTop: '12px',
                padding: '10px 16px',
                backgroundColor: '#F1F5F9',
                borderRadius: '16px',
                display: 'inline-block',
                maxWidth: '100%',
                color: '#334155',
                fontSize: '13px',
                fontWeight: 500,
                lineHeight: 1.5
              }}>
                💬 {bioText}
              </div>
            </div>

            {/* Details Grid */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
              gap: '16px',
              marginTop: '24px',
              paddingTop: '20px',
              borderTop: '1px solid #F1F5F9'
            }}>
              {/* Private ID Card */}
              <div style={{
                padding: '16px',
                borderRadius: '16px',
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Private Identity ID
                  </span>
                  <button
                    onClick={() => handleCopy(privateId, 'id')}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: copiedId ? '#10B981' : '#7B2FBE',
                      fontSize: '11px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '4px',
                      padding: 0
                    }}
                  >
                    {copiedId ? <Check size={12} /> : <Copy size={12} />}
                    <span>{copiedId ? 'Copied' : 'Copy'}</span>
                  </button>
                </div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#0F172A', fontFamily: 'monospace' }}>
                  {privateId}
                </div>
                <p style={{ margin: '4px 0 0', fontSize: '11px', color: '#94A3B8' }}>
                  Share this ID to let contacts find you securely without phone number.
                </p>
              </div>

              {/* Email Address */}
              <div style={{
                padding: '16px',
                borderRadius: '16px',
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
                  <Mail size={13} color="#64748B" />
                  <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Registered Account Email
                  </span>
                </div>
                <div style={{ fontSize: '14px', fontWeight: 700, color: '#0F172A', wordBreak: 'break-all' }}>
                  {user?.email || 'Zero-Knowledge ID (No email bound)'}
                </div>
                <p style={{ margin: '4px 0 0', fontSize: '11px', color: '#94A3B8' }}>
                  {user?.email ? 'Used for password recovery and login authentication.' : 'Complete privacy mode: Zero email or personal tracking.'}
                </p>
              </div>
            </div>

            {/* Quick Action Hub */}
            <div style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '12px',
              marginTop: '24px'
            }}>
              <a
                href="/"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 22px',
                  borderRadius: '14px',
                  background: 'linear-gradient(135deg, #7B2FBE 0%, #E91E8C 100%)',
                  color: '#ffffff',
                  fontSize: '13px',
                  fontWeight: 700,
                  textDecoration: 'none',
                  boxShadow: '0 6px 18px rgba(123,47,190,0.25)'
                }}
              >
                <Zap size={16} />
                <span>Create & Join Encrypted Call</span>
              </a>

              <button
                onClick={() => handleCopy(privateId, 'id')}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 20px',
                  borderRadius: '14px',
                  backgroundColor: '#F1F5F9',
                  border: '1px solid #CBD5E1',
                  color: '#334155',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: 'pointer'
                }}
              >
                {copiedId ? <Check size={16} color="#10B981" /> : <Copy size={16} />}
                <span>{copiedId ? 'Private ID Copied!' : 'Copy Private ID'}</span>
              </button>
            </div>
          </div>
        </div>

        {/* ── SECURITY SPECIFICATIONS CARD ── */}
        <div style={{
          backgroundColor: '#ffffff',
          borderRadius: '24px',
          border: '1px solid #E2E8F0',
          padding: '24px',
          marginBottom: '24px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: 'rgba(16,185,129,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <ShieldCheck size={20} color="#10B981" />
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: '#0F172A' }}>Security & Cryptographic Standards</h3>
              <p style={{ margin: 0, fontSize: '12px', color: '#64748B' }}>Your account is guarded by military-grade local key pairs and zero-knowledge storage.</p>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
            <div style={{ padding: '14px', borderRadius: '14px', backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0' }}>
              <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, textTransform: 'uppercase' }}>Encrypted Transport</span>
              <p style={{ margin: '4px 0 0', fontSize: '13px', fontWeight: 700, color: '#0F172A' }}>AES-256-GCM + ECDH</p>
            </div>

            <div style={{ padding: '14px', borderRadius: '14px', backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0' }}>
              <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, textTransform: 'uppercase' }}>Session Tunnel</span>
              <p style={{ margin: '4px 0 0', fontSize: '13px', fontWeight: 700, color: '#0F172A' }}>WebRTC Peer-to-Peer Direct</p>
            </div>

            <div style={{ padding: '14px', borderRadius: '14px', backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0' }}>
              <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700, textTransform: 'uppercase' }}>Persistence Model</span>
              <p style={{ margin: '4px 0 0', fontSize: '13px', fontWeight: 700, color: '#0F172A' }}>Zero-Knowledge Auto-Purge</p>
            </div>
          </div>

          {user?.publicKey && (
            <div style={{ marginTop: '16px', padding: '12px 14px', borderRadius: '12px', backgroundColor: '#F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0 }}>
                <Key size={14} color="#64748B" />
                <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 700 }}>Public Key:</span>
                <span style={{ fontSize: '11px', color: '#0F172A', fontFamily: 'monospace', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                  {user.publicKey.substring(0, 32)}...
                </span>
              </div>
              <button
                onClick={() => handleCopy(user.publicKey || '', 'key')}
                style={{ background: 'none', border: 'none', color: copiedKey ? '#10B981' : '#7B2FBE', fontSize: '11px', fontWeight: 700, cursor: 'pointer' }}
              >
                {copiedKey ? 'Copied' : 'Copy Key'}
              </button>
            </div>
          )}
        </div>

        {/* ── DANGER ZONE ── */}
        <div style={{
          backgroundColor: '#FFF1F2',
          borderRadius: '24px',
          border: '1px solid #FECDD3',
          padding: '24px',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '16px'
        }}>
          <div>
            <h4 style={{ margin: 0, fontSize: '15px', fontWeight: 800, color: '#9F1239' }}>Delete Account Permanently</h4>
            <p style={{ margin: '4px 0 0', fontSize: '12px', color: '#BE123C' }}>
              This will permanently delete your identity, cryptographic keys, and database records. This action cannot be reversed.
            </p>
          </div>

          <button
            onClick={() => setIsDeleteOpen(true)}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              padding: '10px 18px',
              borderRadius: '12px',
              backgroundColor: '#E11D48',
              color: '#ffffff',
              border: 'none',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer'
            }}
          >
            <Trash2 size={15} />
            <span>Delete Account</span>
          </button>
        </div>
      </main>

      <Footer />

      {/* ── EDIT PROFILE MODAL ── */}
      {isEditOpen && (
        <div style={{
          position: 'fixed',
          inset: 0,
          backgroundColor: 'rgba(15,23,42,0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '16px'
        }}>
          <div style={{
            backgroundColor: '#ffffff',
            borderRadius: '24px',
            maxWidth: '480px',
            width: '100%',
            padding: '28px',
            boxShadow: '0 20px 50px rgba(0,0,0,0.2)',
            position: 'relative',
            maxHeight: '90vh',
            overflowY: 'auto'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: '#0F172A' }}>Edit Profile Information</h3>
              <button
                onClick={() => setIsEditOpen(false)}
                style={{ background: 'none', border: 'none', color: '#94A3B8', cursor: 'pointer', padding: '4px' }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* Photo Upload Area */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '12px', backgroundColor: '#F8FAFC', borderRadius: '16px', border: '1px solid #E2E8F0' }}>
                <div style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  overflow: 'hidden',
                  backgroundColor: '#E2E8F0',
                  flexShrink: 0,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  {editImage ? (
                    <img src={editImage} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <User size={30} color="#94A3B8" />
                  )}
                </div>

                <div style={{ flex: 1 }}>
                  <label
                    htmlFor="photo-upload-input"
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                      padding: '7px 14px',
                      borderRadius: '10px',
                      backgroundColor: '#7B2FBE',
                      color: '#ffffff',
                      fontSize: '12px',
                      fontWeight: 700,
                      cursor: 'pointer'
                    }}
                  >
                    <Camera size={13} />
                    <span>Choose Photo</span>
                  </label>
                  <input
                    id="photo-upload-input"
                    type="file"
                    accept="image/*"
                    onChange={handleImagePick}
                    style={{ display: 'none' }}
                  />
                  {editImage && (
                    <button
                      type="button"
                      onClick={() => setEditImage('')}
                      style={{
                        marginLeft: '8px',
                        background: 'none',
                        border: 'none',
                        color: '#E11D48',
                        fontSize: '12px',
                        fontWeight: 600,
                        cursor: 'pointer'
                      }}
                    >
                      Remove
                    </button>
                  )}
                  <p style={{ margin: '4px 0 0', fontSize: '11px', color: '#64748B' }}>
                    JPG, PNG under 2MB. Saved with database sync.
                  </p>
                </div>
              </div>

              {/* Display Name */}
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                  Display Name
                </label>
                <input
                  type="text"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  placeholder="e.g. Alex"
                  style={{
                    width: '100%',
                    padding: '12px 14px',
                    borderRadius: '12px',
                    border: '1.5px solid #CBD5E1',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              {/* Username */}
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                  Username Handle (@)
                </label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: '12px', top: '12px', color: '#94A3B8', fontWeight: 700 }}>@</span>
                  <input
                    type="text"
                    required
                    value={editUsername}
                    onChange={(e) => setEditUsername(e.target.value.replace(/[^a-zA-Z0-9_]/g, ''))}
                    placeholder="yourhandle"
                    style={{
                      width: '100%',
                      padding: '12px 14px 12px 28px',
                      borderRadius: '12px',
                      border: '1.5px solid #CBD5E1',
                      fontSize: '14px',
                      outline: 'none',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
              </div>

              {/* Status / Bio */}
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                  Status / Bio Message
                </label>
                <textarea
                  rows={3}
                  value={editBio}
                  onChange={(e) => setEditBio(e.target.value)}
                  placeholder="Available | End-to-End Encrypted"
                  maxLength={160}
                  style={{
                    width: '100%',
                    padding: '12px 14px',
                    borderRadius: '12px',
                    border: '1.5px solid #CBD5E1',
                    fontSize: '14px',
                    outline: 'none',
                    resize: 'none',
                    boxSizing: 'border-box'
                  }}
                />
                <span style={{ fontSize: '11px', color: '#94A3B8', float: 'right', marginTop: '2px' }}>
                  {editBio.length}/160
                </span>
              </div>

              {/* Modal Actions */}
              <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
                <button
                  type="button"
                  onClick={() => setIsEditOpen(false)}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '12px',
                    backgroundColor: '#F1F5F9',
                    border: 'none',
                    color: '#475569',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  style={{
                    flex: 1.5,
                    padding: '12px',
                    borderRadius: '12px',
                    background: 'linear-gradient(135deg, #7B2FBE 0%, #E91E8C 100%)',
                    border: 'none',
                    color: '#ffffff',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: saving ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '6px'
                  }}
                >
                  {saving ? (
                    <RefreshCw size={15} className="animate-spin" />
                  ) : (
                    <Save size={15} />
                  )}
                  <span>{saving ? 'Saving...' : 'Save Profile Changes'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── DELETE ACCOUNT CONFIRMATION MODAL ── */}
      {isDeleteOpen && (
        <div style={{
          position: 'fixed',
          inset: 0,
          backgroundColor: 'rgba(15,23,42,0.6)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '16px'
        }}>
          <div style={{
            backgroundColor: '#ffffff',
            borderRadius: '24px',
            maxWidth: '440px',
            width: '100%',
            padding: '28px',
            boxShadow: '0 20px 50px rgba(0,0,0,0.2)',
            textAlign: 'center'
          }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '50%', backgroundColor: '#FFF1F2', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
              <Trash2 size={26} color="#E11D48" />
            </div>

            <h3 style={{ margin: '0 0 8px', fontSize: '18px', fontWeight: 800, color: '#0F172A' }}>
              Permanently Delete Account?
            </h3>
            <p style={{ margin: '0 0 24px', fontSize: '13px', color: '#64748B', lineHeight: 1.5 }}>
              This action will permanently delete your identity (<strong style={{ color: '#0F172A' }}>{userHandle}</strong>), all encrypted conversations, and cryptographic keys. You cannot undo this.
            </p>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setIsDeleteOpen(false)}
                disabled={deleting}
                style={{
                  flex: 1,
                  padding: '12px',
                  borderRadius: '12px',
                  backgroundColor: '#F1F5F9',
                  border: 'none',
                  color: '#475569',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: 'pointer'
                }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleDeleteAccount}
                disabled={deleting}
                style={{
                  flex: 1,
                  padding: '12px',
                  borderRadius: '12px',
                  backgroundColor: '#E11D48',
                  border: 'none',
                  color: '#ffffff',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: deleting ? 'not-allowed' : 'pointer'
                }}
              >
                {deleting ? 'Deleting...' : 'Yes, Delete Permanently'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WebProfile;
