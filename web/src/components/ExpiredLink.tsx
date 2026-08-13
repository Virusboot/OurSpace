import React from 'react';
import { Clock, ShieldX, ArrowRight } from 'lucide-react';

export const ExpiredLink: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-black text-white relative">
      <div className="glass-panel max-w-md w-full rounded-2xl p-8 text-center animate-fade-in">
        <div className="w-16 h-16 rounded-full bg-rose-500/10 border border-rose-500/30 flex items-center justify-center mx-auto mb-4">
          <Clock className="w-8 h-8 text-rose-400" />
        </div>
        <h1 className="text-xl font-bold font-heading text-white">Call Link Expired</h1>
        <p className="text-gray-400 text-sm mt-2">
          This private call link has expired. Secure call links are temporary and expire automatically for your privacy.
        </p>
        <p className="text-xs text-gray-500 mt-4">Ask the host to generate a new call link.</p>
      </div>
    </div>
  );
};

export const InvalidLink: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-black text-white relative">
      <div className="glass-panel max-w-md w-full rounded-2xl p-8 text-center animate-fade-in">
        <div className="w-16 h-16 rounded-full bg-rose-500/10 border border-rose-500/30 flex items-center justify-center mx-auto mb-4">
          <ShieldX className="w-8 h-8 text-rose-400" />
        </div>
        <h1 className="text-xl font-bold font-heading text-white">Invalid Call Link</h1>
        <p className="text-gray-400 text-sm mt-2">
          This private call link is no longer available or may have been revoked by the host.
        </p>
      </div>
    </div>
  );
};
