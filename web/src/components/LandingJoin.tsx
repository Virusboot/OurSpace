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
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-black">
      <div className="glow-bg w-[500px] h-[500px] -top-32 -left-32 opacity-30"></div>
      <div className="glow-bg w-[400px] h-[400px] -bottom-32 -right-32 opacity-20"></div>

      <div className="glass-panel max-w-md w-full rounded-2xl p-8 animate-fade-in relative z-10">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center mb-4">
            <Shield className="w-7 h-7 text-emerald-400" />
          </div>
          <h1 className="text-2xl font-bold font-heading text-white tracking-tight">OurSpace Call</h1>
          <p className="text-gray-400 text-sm mt-1">Someone invited you to an end-to-end encrypted call.</p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs text-center">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-300 mb-1">Your Guest Nickname</label>
            <input
              type="text"
              required
              placeholder="e.g. Alex"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition"
            />
          </div>

          {pinRequired && (
            <div>
              <label className="block text-xs font-medium text-gray-300 mb-1">Call Protection PIN</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-gray-400 absolute left-3 top-3.5" />
                <input
                  type="password"
                  required
                  placeholder="Enter call PIN"
                  value={pin}
                  onChange={(e) => setPin(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 rounded-xl bg-white/5 border border-white/10 text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition"
                />
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={!nickname.trim()}
            className="w-full py-3.5 px-4 rounded-xl bg-emerald-500 hover:bg-emerald-600 font-semibold text-black flex items-center justify-center space-x-2 text-sm transition shadow-lg shadow-emerald-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
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
        <div className="mt-6 pt-6 border-t border-white/10 space-y-3">
          <div className="flex items-center space-x-2 text-emerald-400 text-xs font-semibold">
            <Smartphone className="w-4 h-4" />
            <span>Have the Mobile App?</span>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <a
              href={`ourspace://c/${token || ''}`}
              className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-white/5 border border-white/10 text-white hover:bg-white/10 text-xs font-medium transition cursor-pointer text-center"
            >
              <ExternalLink className="w-3.5 h-3.5 text-emerald-400" />
              <span>Open in App</span>
            </a>

            <a
              href="/downloads/ourspace.apk"
              download
              className="flex items-center justify-center space-x-1.5 py-2.5 px-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20 text-xs font-medium transition cursor-pointer text-center"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download APK</span>
            </a>
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-white/5 flex items-center space-x-3 text-xs text-gray-500">
          <Shield className="w-4 h-4 text-gray-600 flex-shrink-0" />
          <p>
            <span className="font-semibold text-gray-400">Privacy Notice:</span> For maximum screenshot protection and encrypted chat, download the native mobile app.
          </p>
        </div>
      </div>
    </div>
  );
};
export default LandingJoin;
