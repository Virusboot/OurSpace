import React, { useState } from 'react';
import { Shield, Lock, Video, Phone, EyeOff, Key, Sparkles, ArrowRight } from 'lucide-react';

export const WebHome: React.FC = () => {
  const [inputToken, setInputToken] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const handleJoinByToken = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = inputToken.trim();
    if (!trimmed) {
      setErrorMsg('Please enter a valid call link or token');
      return;
    }

    if (trimmed.includes('/c/')) {
      const tokenPart = trimmed.split('/c/')[1];
      window.location.href = `/c/${tokenPart}`;
    } else {
      window.location.href = `/c/${trimmed}`;
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-blue-600 selection:text-white">
      {/* Navigation Header */}
      <header className="border-b border-slate-800/80 bg-slate-950/80 backdrop-blur-md sticky top-0 z-50 px-6 py-4">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-blue-600/20 border border-blue-500/40 flex items-center justify-center shadow-lg shadow-blue-500/10">
              <Shield className="w-5 h-5 text-blue-500" />
            </div>
            <div>
              <h1 className="font-bold text-lg tracking-tight text-white flex items-center gap-2">
                OurSpace <span className="text-xs px-2 py-0.5 rounded-full bg-blue-500/10 border border-blue-500/30 text-blue-400 font-semibold">E2EE</span>
              </h1>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <a
              href="https://github.com/Virusboot/OurSpace"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-semibold text-slate-400 hover:text-white transition-colors"
            >
              GitHub Source
            </a>
            <button
              onClick={() => {
                alert('OurSpace App v1.0.0 is built with Zero-Knowledge E2EE Architecture.');
              }}
              className="text-xs font-bold px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white transition-all shadow-lg shadow-blue-600/25"
            >
              Get Mobile App
            </button>
          </div>
        </div>
      </header>

      {/* Main Hero Container */}
      <main className="max-w-4xl mx-auto px-6 py-12 flex-1 flex flex-col items-center justify-center text-center">
        {/* Security Badge */}
        <div className="inline-flex items-center space-x-2 px-3 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-bold tracking-wide uppercase mb-6 shadow-inner">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Zero-Knowledge Peer-to-Peer Encryption</span>
        </div>

        {/* Hero Title */}
        <h2 className="text-4xl md:text-6xl font-black text-white tracking-tight mb-4 leading-tight">
          Ultra-Private Calls & <br />
          <span className="bg-gradient-to-r from-blue-400 via-cyan-400 to-indigo-500 bg-clip-text text-transparent">
            Secure Communications
          </span>
        </h2>

        <p className="text-slate-400 text-base md:text-lg max-w-2xl mb-8 leading-relaxed">
          Join E2EE WebRTC voice and video calls with zero registration, zero phone numbers, and complete cryptographic privacy.
        </p>

        {/* Call Link / Token Input Card */}
        <div className="w-full max-w-md bg-slate-900/90 border border-slate-800 rounded-2xl p-6 shadow-2xl backdrop-blur-xl mb-12">
          <form onSubmit={handleJoinByToken} className="flex flex-col gap-3">
            <label className="text-left text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center justify-between">
              <span>Join Encrypted Call</span>
              <span className="text-blue-400 text-[11px] font-mono">P2P Room</span>
            </label>
            <div className="relative">
              <input
                type="text"
                value={inputToken}
                onChange={(e) => {
                  setInputToken(e.target.value);
                  setErrorMsg('');
                }}
                placeholder="Paste Call Link or Token (e.g. c/token)"
                className="w-full bg-slate-950/80 border border-slate-800 focus:border-blue-500 rounded-xl px-4 py-3.5 text-sm text-white placeholder-slate-500 focus:outline-none transition-all"
              />
              <button
                type="submit"
                className="absolute right-2 top-2 bottom-2 px-4 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-bold text-xs flex items-center space-x-1.5 transition-all shadow-md shadow-blue-600/30"
              >
                <span>Join</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
            {errorMsg && <p className="text-rose-400 text-xs font-semibold text-left">{errorMsg}</p>}
          </form>
        </div>

        {/* Feature Highlights Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 w-full text-left">
          <div className="bg-slate-900/50 border border-slate-800/80 p-5 rounded-2xl">
            <div className="w-9 h-9 rounded-lg bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400 mb-3">
              <Lock className="w-4 h-4" />
            </div>
            <h3 className="font-bold text-white text-sm mb-1">AES-256-GCM E2EE</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Messages and media streams are encrypted on device before transmission.
            </p>
          </div>

          <div className="bg-slate-900/50 border border-slate-800/80 p-5 rounded-2xl">
            <div className="w-9 h-9 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 mb-3">
              <EyeOff className="w-4 h-4" />
            </div>
            <h3 className="font-bold text-white text-sm mb-1">Ghost Mode & Disappearing</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              30s self-destructing timers and screenshot overlay protection.
            </p>
          </div>

          <div className="bg-slate-900/50 border border-slate-800/80 p-5 rounded-2xl">
            <div className="w-9 h-9 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 mb-3">
              <Video className="w-4 h-4" />
            </div>
            <h3 className="font-bold text-white text-sm mb-1">WebRTC P2P Voice & Video</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Direct peer-to-peer encrypted calls with zero server audio/video relay storage.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/60 py-6 px-6 text-center text-xs text-slate-500">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-3">
          <p>© 2026 OurSpace Privacy Chat. All rights reserved.</p>
          <div className="flex items-center space-x-4">
            <span className="text-blue-400 font-semibold">Zero Logs Policy</span>
            <span>•</span>
            <span className="text-slate-400">End-to-End Encrypted</span>
          </div>
        </div>
      </footer>
    </div>
  );
};
