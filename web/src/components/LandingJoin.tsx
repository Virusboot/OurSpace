import React, { useState, useEffect } from 'react';
import { Shield, Video, Mic, Lock, Smartphone, Download, ExternalLink, User, LogIn, Globe } from 'lucide-react';

interface LandingJoinProps {
  token: string | null;
  callType: 'audio' | 'video';
  pinRequired: boolean;
  onJoin: (nickname: string, pin?: string) => void;
  errorMsg?: string;
}

export const LandingJoin: React.FC<LandingJoinProps> = ({ token, callType, pinRequired, onJoin, errorMsg }) => {
  const [nickname, setNickname] = useState('');
  const [pin, setPin] = useState('');
  const [activeTab, setActiveTab] = useState<'guest' | 'login'>('guest');

  useEffect(() => {
    if (token) {
      // Auto-redirect to the custom app scheme immediately on mobile device detection
      const userAgent = navigator.userAgent || navigator.vendor || (window as any).opera;
      const isMobile = /android|iPad|iPhone|iPod/.test(userAgent.toLowerCase());
      if (isMobile) {
        window.location.href = `ourspace://c/${token}`;
      }
    }
  }, [token]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nickname.trim()) return;
    onJoin(nickname.trim(), pinRequired ? pin : undefined);
  };

  const returnUrl = encodeURIComponent(window.location.pathname);

  return (
    <div className="min-h-screen flex flex-col bg-[#F8FAFC] relative overflow-hidden">
      {/* Glow background effects */}
      <div className="glow-bg w-[500px] h-[500px] -top-32 -left-32 opacity-15 pointer-events-none"></div>
      <div className="glow-bg w-[400px] h-[400px] -bottom-32 -right-32 opacity-10 pointer-events-none"></div>

      {/* Top Header Bar for Brand Recognition */}
      <header className="w-full bg-white/80 backdrop-blur-md border-b border-slate-200/80 px-6 py-4 flex items-center justify-between z-20 sticky top-0 shadow-sm">
        <a href="/" className="flex items-center space-x-3 group">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#7B2FBE] to-[#E91E8C] flex items-center justify-center shadow-md shadow-purple-500/20">
            <Shield className="w-5 h-5 text-white" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-bold text-lg font-heading text-[#0F172A] tracking-tight group-hover:text-[#7B2FBE] transition">OurSpace</span>
              <span className="text-[10px] uppercase tracking-wider font-extrabold px-2 py-0.5 rounded-full bg-purple-100 text-[#7B2FBE]">Web</span>
            </div>
            <p className="text-[11px] text-[#64748B]">Official Privacy-Focused Encrypted Space</p>
          </div>
        </a>

        <div className="flex items-center space-x-3">
          <a
            href="/"
            className="hidden sm:inline-flex items-center text-xs font-semibold text-[#64748B] hover:text-[#0F172A] transition"
          >
            Website Home
          </a>
          <a
            href={`/login?return=${returnUrl}`}
            className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-[#7B2FBE] hover:bg-[#6823a3] text-white text-xs font-semibold shadow-md shadow-purple-500/20 transition"
          >
            <LogIn className="w-3.5 h-3.5" />
            <span>Login to Website</span>
          </a>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 flex items-center justify-center p-4 relative z-10 my-6">
        <div className="glass-panel max-w-md w-full rounded-3xl p-8 animate-fade-in shadow-2xl bg-white/90 border border-slate-200">
          
          {/* Website Banner Info */}
          <div className="flex items-center justify-center space-x-1.5 mb-4 px-3 py-1.5 rounded-full bg-slate-100 border border-slate-200 text-slate-600 text-[11px] font-medium mx-auto w-fit">
            <Globe className="w-3.5 h-3.5 text-[#7B2FBE]" />
            <span>Joining via <strong className="text-[#0F172A]">our-space-wheat.vercel.app</strong></span>
          </div>

          <div className="flex flex-col items-center text-center mb-6">
            <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-3">
              <Shield className="w-7 h-7 text-emerald-500" />
            </div>
            <h1 className="text-2xl font-bold font-heading text-[#0F172A] tracking-tight">Private Encrypted Call</h1>
            <p className="text-[#64748B] text-xs mt-1">
              You are invited to an end-to-end encrypted peer-to-peer call.
            </p>
          </div>

          {/* Option Selector Tabs: Direct Guest vs Account Login */}
          <div className="grid grid-cols-2 gap-1 p-1 bg-slate-100 rounded-2xl mb-6 border border-slate-200">
            <button
              type="button"
              onClick={() => setActiveTab('guest')}
              className={`flex items-center justify-center space-x-1.5 py-2 px-3 rounded-xl text-xs font-bold transition ${
                activeTab === 'guest'
                  ? 'bg-white text-[#7B2FBE] shadow-sm'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              <User className="w-3.5 h-3.5" />
              <span>Direct Guest Join</span>
            </button>
            <a
              href={`/login?return=${returnUrl}`}
              className="flex items-center justify-center space-x-1.5 py-2 px-3 rounded-xl text-xs font-bold text-slate-500 hover:text-[#7B2FBE] transition"
            >
              <LogIn className="w-3.5 h-3.5" />
              <span>Account Sign In</span>
            </a>
          </div>

          {errorMsg && (
            <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-600 text-xs text-center font-medium">
              {errorMsg}
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-[#475569] mb-1">Your Guest Display Name</label>
              <input
                type="text"
                required
                placeholder="e.g. Alex"
                value={nickname}
                onChange={(e) => setNickname(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-slate-100/80 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-[#7B2FBE] focus:ring-1 focus:ring-[#7B2FBE] text-sm transition"
              />
            </div>

            {pinRequired && (
              <div>
                <label className="block text-xs font-semibold text-[#475569] mb-1">Call Protection PIN</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                  <input
                    type="password"
                    required
                    placeholder="Enter call PIN"
                    value={pin}
                    onChange={(e) => setPin(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-100/80 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-[#7B2FBE] focus:ring-1 focus:ring-[#7B2FBE] text-sm transition"
                  />
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={!nickname.trim()}
              className="w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white hover:opacity-90 font-semibold flex items-center justify-center space-x-2 text-sm transition shadow-lg shadow-purple-500/20 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
            >
              {callType === 'video' ? (
                <>
                  <Video className="w-4 h-4" />
                  <span>Join Video Call on Website</span>
                </>
              ) : (
                <>
                  <Mic className="w-4 h-4" />
                  <span>Join Audio Call on Website</span>
                </>
              )}
            </button>
          </form>

          {/* Deep Linking and App Downloads Section */}
          <div className="mt-6 pt-6 border-t border-slate-200/80 space-y-3">
            <div className="flex items-center space-x-2 text-[#7B2FBE] text-xs font-bold">
              <Smartphone className="w-4 h-4" />
              <span>Or Use Mobile App</span>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <a
                href={`ourspace://c/${token || ''}`}
                className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-slate-100 border border-slate-200 text-[#0F172A] hover:bg-slate-200 text-xs font-semibold transition cursor-pointer text-center"
              >
                <ExternalLink className="w-3.5 h-3.5 text-[#7B2FBE]" />
                <span>Open Mobile App</span>
              </a>

              <a
                href="https://play.google.com/store/apps/details?id=com.ourspace.app"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-purple-500/10 border border-purple-500/20 text-[#7B2FBE] hover:bg-purple-500/20 text-xs font-semibold transition cursor-pointer text-center"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Get Play Store App</span>
              </a>
            </div>
          </div>

          {/* Web Login Alternative */}
          <div className="mt-5 pt-4 border-t border-slate-200/60 text-center">
            <p className="text-xs text-[#64748B] mb-2">
              Already have an OurSpace Account?
            </p>
            <a
              href={`/login?return=${returnUrl}`}
              className="inline-flex items-center justify-center gap-1.5 px-5 py-2.5 rounded-xl w-full bg-slate-100 hover:bg-slate-200 border border-slate-200 text-[#7B2FBE] text-xs font-bold transition"
            >
              <LogIn className="w-3.5 h-3.5" />
              <span>Log In to OurSpace Account on Web</span>
            </a>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full py-4 text-center text-xs text-slate-400 border-t border-slate-200/60 bg-white/50">
        <p>© OurSpace — Privacy-Focused Encrypted Space | Host: <span className="font-semibold text-slate-600">our-space-wheat.vercel.app</span></p>
      </footer>
    </div>
  );
};
export default LandingJoin;
