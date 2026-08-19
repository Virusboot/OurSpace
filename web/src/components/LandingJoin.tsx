import React, { useState, useEffect } from 'react';
import { Shield, Video, Mic, Lock, Smartphone, Download, ExternalLink } from 'lucide-react';

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

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-[#F8FAFC]">
      <div className="glow-bg w-[500px] h-[500px] -top-32 -left-32 opacity-15"></div>
      <div className="glow-bg w-[400px] h-[400px] -bottom-32 -right-32 opacity-10"></div>

      <div className="glass-panel max-w-md w-full rounded-3xl p-8 animate-fade-in relative z-10">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-4">
            <Shield className="w-7 h-7 text-emerald-400" />
          </div>
          <h1 className="text-2xl font-bold font-heading text-[#0F172A] tracking-tight">OurSpace Call</h1>
          <p className="text-[#64748B] text-sm mt-1">Someone invited you to an end-to-end encrypted call.</p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs text-center">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-[#475569] mb-1">Your Guest Nickname</label>
            <input
              type="text"
              required
              placeholder="e.g. Alex"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-100/70 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition"
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
                  className="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-100/70 border border-slate-200 text-[#0F172A] placeholder-slate-400 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition"
                />
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={!nickname.trim()}
            className="w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-[#7B2FBE] to-[#E91E8C] text-white hover:opacity-90 font-semibold flex items-center justify-center space-x-2 text-sm transition shadow-lg shadow-purple-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {callType === 'video' ? (
              <>
                <Video className="w-4 h-4" />
                <span>Join Video Call</span>
              </>
            ) : (
              <>
                <Mic className="w-4 h-4" />
                <span>Join Audio Call</span>
              </>
            )}
          </button>
        </form>

        {/* Deep Linking and App Downloads Section */}
        <div className="mt-6 pt-6 border-t border-slate-100 space-y-3">
          <div className="flex items-center space-x-2 text-[#7B2FBE] text-xs font-bold">
            <Smartphone className="w-4 h-4" />
            <span>Have the Mobile App?</span>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <a
              href={`ourspace://c/${token || ''}`}
              className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-slate-100 border border-slate-200 text-[#0F172A] hover:bg-slate-200 text-xs font-semibold transition cursor-pointer text-center"
            >
              <ExternalLink className="w-3.5 h-3.5 text-[#7B2FBE]" />
              <span>Open in App</span>
            </a>

            <a
              href="https://play.google.com/store/apps/details?id=com.ourspace.app"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-purple-500/10 border border-purple-500/20 text-[#7B2FBE] hover:bg-purple-500/20 text-xs font-semibold transition cursor-pointer text-center"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Get on Play Store</span>
            </a>
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-slate-100/50 flex items-center space-x-3 text-xs text-slate-400">
          <Shield className="w-4 h-4 text-slate-300 flex-shrink-0" />
          <p>
            <span className="font-semibold text-slate-500">Privacy Notice:</span> For maximum screenshot protection and encrypted chat, download the native mobile app.
          </p>
        </div>

        {/* Web Login / Register CTA */}
        <div className="mt-5 pt-4 border-t border-slate-100/50 text-center">
          <p className="text-xs text-[#64748B] mb-2">
            Want to use OurSpace without the app?
          </p>
          <a
            href={`/login?return=${encodeURIComponent(window.location.pathname)}`}
            className="inline-flex items-center justify-center gap-1.5 px-5 py-2.5 rounded-xl w-full bg-gradient-to-r from-[#7B2FBE]/10 to-[#E91E8C]/10 border border-[#7B2FBE]/20 text-[#7B2FBE] hover:from-[#7B2FBE]/20 hover:to-[#E91E8C]/20 text-xs font-semibold transition"
          >
            🔐 Login or Create Account — No App Needed
          </a>
        </div>
      </div>
    </div>
  );
};
export default LandingJoin;
