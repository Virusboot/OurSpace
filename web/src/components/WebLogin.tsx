import React, { useState } from 'react';
import { Shield, Eye, EyeOff, User, Mail, Lock, LogIn, UserPlus, ArrowLeft } from 'lucide-react';

const BACKEND_HOST = 'ourspace-backend.onrender.com';
const API_BASE = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? ''
  : `https://${BACKEND_HOST}`;

interface WebLoginProps {
  onLoginSuccess?: (user: any, token: string) => void;
  returnTo?: string; // e.g. '/c/<token>' to redirect after login
}

type Mode = 'login' | 'register';

export const WebLogin: React.FC<WebLoginProps> = ({ onLoginSuccess, returnTo }) => {
  const [mode, setMode] = useState<Mode>('login');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      const endpoint = mode === 'login' ? '/api/auth/login' : '/api/auth/register';
      const body = mode === 'login'
        ? { username: username.trim(), password }
        : { username: username.trim().startsWith('@') ? username.trim() : `@${username.trim()}`, email: email.trim(), password };

      const res = await fetch(`${API_BASE}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Something went wrong');

      // Store token in sessionStorage for this browser session
      sessionStorage.setItem('ws_token', data.token);
      sessionStorage.setItem('ws_user', JSON.stringify(data.user));

      setSuccess(mode === 'login' ? 'Login successful! Redirecting...' : 'Account created! Redirecting...');

      if (onLoginSuccess) {
        onLoginSuccess(data.user, data.token);
      } else {
        // Redirect back to the call link or home
        setTimeout(() => {
          window.location.href = returnTo || '/';
        }, 800);
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-[#F8FAFC]">
      <div className="glow-bg w-[500px] h-[500px] -top-32 -left-32 opacity-15"></div>
      <div className="glow-bg w-[400px] h-[400px] -bottom-32 -right-32 opacity-10"></div>

      <div className="glass-panel max-w-md w-full rounded-3xl p-8 animate-fade-in relative z-10">
        {/* Logo + Title */}
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#7B2FBE]/20 to-[#E91E8C]/10 border border-[#7B2FBE]/20 flex items-center justify-center mb-4">
            <Shield className="w-7 h-7 text-[#7B2FBE]" />
          </div>
          <h1 className="text-2xl font-bold font-heading text-[#0F172A] tracking-tight">
            {mode === 'login' ? 'Sign in to OurSpace' : 'Create an Account'}
          </h1>
          <p className="text-[#64748B] text-sm mt-1">
            {mode === 'login'
              ? 'Access your encrypted chats & calls from the web.'
              : 'Join OurSpace and start encrypted conversations.'}
          </p>
        </div>

        {/* Mode Tabs */}
        <div className="flex rounded-xl overflow-hidden border border-slate-200 mb-6">
          <button
            type="button"
            onClick={() => { setMode('login'); setError(null); }}
            className={`flex-1 py-2.5 text-sm font-semibold transition ${
              mode === 'login'
                ? 'bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white'
                : 'bg-white text-[#64748B] hover:bg-slate-50'
            }`}
          >
            <span className="flex items-center justify-center gap-1.5">
              <LogIn className="w-3.5 h-3.5" /> Login
            </span>
          </button>
          <button
            type="button"
            onClick={() => { setMode('register'); setError(null); }}
            className={`flex-1 py-2.5 text-sm font-semibold transition ${
              mode === 'register'
                ? 'bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white'
                : 'bg-white text-[#64748B] hover:bg-slate-50'
            }`}
          >
            <span className="flex items-center justify-center gap-1.5">
              <UserPlus className="w-3.5 h-3.5" /> Register
            </span>
          </button>
        </div>

        {/* Error / Success */}
        {error && (
          <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-600 text-xs text-center">
            {error}
          </div>
        )}
        {success && (
          <div className="mb-4 p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 text-xs text-center">
            {success}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Username */}
          <div>
            <label className="block text-xs font-semibold text-[#475569] mb-1">
              {mode === 'login' ? 'Username or Private ID' : 'Username'}
            </label>
            <div className="relative">
              <User className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
              <input
                type="text"
                required
                placeholder={mode === 'login' ? '@yourname or USER-XXXX' : '@yourname'}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-100/70 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-[#7B2FBE] focus:ring-1 focus:ring-[#7B2FBE] text-sm transition"
              />
            </div>
          </div>

          {/* Email — only for register */}
          {mode === 'register' && (
            <div>
              <label className="block text-xs font-semibold text-[#475569] mb-1">Email</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="email"
                  required
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-100/70 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-[#7B2FBE] focus:ring-1 focus:ring-[#7B2FBE] text-sm transition"
                />
              </div>
            </div>
          )}

          {/* Password */}
          <div>
            <label className="block text-xs font-semibold text-[#475569] mb-1">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
              <input
                type={showPass ? 'text' : 'password'}
                required
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-10 pr-10 py-3 rounded-xl bg-slate-100/70 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-[#7B2FBE] focus:ring-1 focus:ring-[#7B2FBE] text-sm transition"
              />
              <button
                type="button"
                onClick={() => setShowPass(!showPass)}
                className="absolute right-3 top-3.5 text-slate-400 hover:text-slate-600 transition"
              >
                {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading || !username.trim() || !password}
            className="w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white hover:opacity-90 font-semibold flex items-center justify-center space-x-2 text-sm transition shadow-lg shadow-purple-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : mode === 'login' ? (
              <>
                <LogIn className="w-4 h-4" />
                <span>Login to OurSpace</span>
              </>
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                <span>Create Account</span>
              </>
            )}
          </button>
        </form>

        {/* Back link */}
        <div className="mt-5 text-center">
          <a
            href={returnTo || '/'}
            className="inline-flex items-center gap-1.5 text-xs text-[#7B2FBE] hover:underline font-semibold"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            {returnTo ? 'Back to Call' : 'Back to Home'}
          </a>
        </div>

        {/* Privacy Notice */}
        <div className="mt-4 pt-4 border-t border-slate-100/50 flex items-start space-x-2 text-xs text-slate-400">
          <Shield className="w-4 h-4 text-slate-300 flex-shrink-0 mt-0.5" />
          <p>
            <span className="font-semibold text-slate-500">Privacy Notice: </span>
            Your identity and messages are always end-to-end encrypted. We never store plaintext passwords.
          </p>
        </div>
      </div>
    </div>
  );
};

export default WebLogin;
