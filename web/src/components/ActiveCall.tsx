import React, { useEffect, useRef, useState } from 'react';
import { Mic, MicOff, Video, VideoOff, PhoneOff, ShieldAlert, Volume2, ShieldCheck, Lock } from 'lucide-react';

interface ActiveCallProps {
  callType: 'audio' | 'video';
  localStream: MediaStream | null;
  remoteStream: MediaStream | null;
  nickname: string;
  connectionState: string;
  securityAlert?: string | null;
  onToggleMic: (enabled: boolean) => void;
  onToggleCam: (enabled: boolean) => void;
  onLeaveCall: () => void;
  onSecurityEvent?: (event: string) => void;
}

export const ActiveCall: React.FC<ActiveCallProps> = ({
  callType,
  localStream,
  remoteStream,
  nickname,
  connectionState,
  securityAlert,
  onToggleMic,
  onToggleCam,
  onLeaveCall,
  onSecurityEvent
}) => {
  const localVideoRef = useRef<HTMLVideoElement>(null);
  const remoteVideoRef = useRef<HTMLVideoElement>(null);
  const [micEnabled, setMicEnabled] = useState(true);
  const [camEnabled, setCamEnabled] = useState(callType === 'video');
  const [secondsElapsed, setSecondsElapsed] = useState(0);
  const [privacyShieldActive, setPrivacyShieldActive] = useState(false);
  const [privacyNotice, setPrivacyNotice] = useState<string | null>(null);

  useEffect(() => {
    if (localVideoRef.current && localStream) {
      localVideoRef.current.srcObject = localStream;
    }
  }, [localStream]);

  useEffect(() => {
    if (remoteVideoRef.current && remoteStream) {
      remoteVideoRef.current.srcObject = remoteStream;
    }
  }, [remoteStream]);

  useEffect(() => {
    const timer = setInterval(() => {
      setSecondsElapsed((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // 🛡️ Web Anti-Screenshot & Screen Recording Privacy Protection Listeners
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Detect PrintScreen, Cmd+Shift+3/4/5 (macOS screenshot), Ctrl+Shift+S (Snipping tool), F12, Ctrl+P
      const key = e.key.toLowerCase();
      const isMacScreenshot = (e.metaKey || e.ctrlKey) && e.shiftKey && (key === '3' || key === '4' || key === '5' || key === 's');
      const isPrintScreen = key === 'printscreen' || key === 'prtscr' || key === 'sysreq';
      const isCtrlP = (e.ctrlKey || e.metaKey) && key === 'p';

      if (isPrintScreen || isMacScreenshot || isCtrlP) {
        e.preventDefault();
        triggerPrivacyShield('Screenshot / Screen Capture shortcut blocked');
      }
    };

    const handleVisibilityChange = () => {
      if (document.hidden) {
        triggerPrivacyShield('Tab switched / backgrounded (Screen capture prevention)');
      } else {
        // Auto-restore when returning to tab
        setTimeout(() => setPrivacyShieldActive(false), 1500);
      }
    };

    const handleWindowBlur = () => {
      triggerPrivacyShield('Window focus lost (Overlay / Recorder active)');
    };

    const handleWindowFocus = () => {
      setTimeout(() => setPrivacyShieldActive(false), 1500);
    };

    const triggerPrivacyShield = (reason: string) => {
      setPrivacyShieldActive(true);
      setPrivacyNotice(reason);
      if (onSecurityEvent) {
        onSecurityEvent(reason);
      }
      setTimeout(() => setPrivacyNotice(null), 5000);
    };

    window.addEventListener('keydown', handleKeyDown);
    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('blur', handleWindowBlur);
    window.addEventListener('focus', handleWindowFocus);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('blur', handleWindowBlur);
      window.removeEventListener('focus', handleWindowFocus);
    };
  }, [onSecurityEvent]);

  const formatTimer = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const handleMicClick = () => {
    const next = !micEnabled;
    setMicEnabled(next);
    onToggleMic(next);
  };

  const handleCamClick = () => {
    const next = !camEnabled;
    setCamEnabled(next);
    onToggleCam(next);
  };

  return (
    <div className="fixed inset-0 bg-black text-white flex flex-col justify-between p-4 sm:p-6 overflow-hidden select-none">
      {/* Top Bar */}
      <div className="flex items-center justify-between z-20">
        <div className="flex items-center space-x-3 bg-white/10 backdrop-blur-md px-4 py-2 rounded-full border border-white/10">
          <div className={`w-2.5 h-2.5 rounded-full ${connectionState === 'connected' ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`}></div>
          <span className="text-xs font-medium uppercase tracking-wider">{connectionState === 'connected' ? 'Encrypted Call' : connectionState}</span>
          <span className="text-xs font-mono text-gray-400 border-l border-white/20 pl-3">{formatTimer(secondsElapsed)}</span>
        </div>

        <div className="flex items-center space-x-2">
          <div className="hidden sm:flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Anti-Capture Active</span>
          </div>
          <div className="text-xs font-medium text-gray-400 bg-white/5 px-3 py-1.5 rounded-lg border border-white/10">
            Guest: <span className="text-white font-semibold">{nickname}</span>
          </div>
        </div>
      </div>

      {/* Security Notification Banners */}
      {(securityAlert || privacyNotice) && (
        <div className="absolute top-20 left-1/2 -translate-x-1/2 z-30 max-w-md w-full px-4 animate-fade-in">
          <div className="p-3.5 rounded-2xl bg-amber-500/20 border border-amber-500/40 text-amber-300 text-xs flex items-center space-x-3 backdrop-blur-xl shadow-2xl">
            <ShieldAlert className="w-5 h-5 flex-shrink-0 text-amber-400" />
            <div>
              <p className="font-bold text-amber-200">Privacy Protection Triggered</p>
              <p className="text-[11px] text-amber-300/90">{securityAlert || privacyNotice}</p>
            </div>
          </div>
        </div>
      )}

      {/* Main Video/Audio Center Stage with Privacy Shield Overlay */}
      <div className="relative flex-1 my-4 rounded-2xl overflow-hidden bg-neutral-900 border border-white/10 flex items-center justify-center">
        
        {/* Anti-Screenshot / Privacy Shield Overlay */}
        {privacyShieldActive && (
          <div className="absolute inset-0 z-40 bg-black/95 backdrop-blur-3xl flex flex-col items-center justify-center p-6 text-center animate-fade-in">
            <div className="w-16 h-16 rounded-2xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-center mb-4 shadow-2xl">
              <Lock className="w-8 h-8 text-purple-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-1">Privacy Protection Active</h3>
            <p className="text-xs text-gray-400 max-w-xs leading-relaxed">
              Video stream obscured to prevent screenshot or screen recording capture. Return focus to window to resume.
            </p>
          </div>
        )}

        {callType === 'video' ? (
          <>
            {/* Remote Stream */}
            {remoteStream ? (
              <video
                ref={remoteVideoRef}
                autoPlay
                playsInline
                className={`w-full h-full object-cover transition-all duration-300 ${
                  privacyShieldActive ? 'blur-3xl brightness-0' : ''
                }`}
              />
            ) : (
              <div className="flex flex-col items-center justify-center text-center p-6">
                <div className="w-20 h-20 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4">
                  <span className="text-2xl font-bold font-heading text-emerald-400">{nickname.substring(0, 2).toUpperCase()}</span>
                </div>
                <p className="text-sm font-medium text-gray-300">Waiting for participant to connect...</p>
              </div>
            )}

            {/* Local Stream Thumbnail */}
            <div className="absolute bottom-4 right-4 w-32 h-44 rounded-xl overflow-hidden border border-white/20 shadow-2xl bg-black">
              {camEnabled ? (
                <video
                  ref={localVideoRef}
                  autoPlay
                  muted
                  playsInline
                  className={`w-full h-full object-cover transform -scale-x-100 transition-all duration-300 ${
                    privacyShieldActive ? 'blur-3xl brightness-0' : ''
                  }`}
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-neutral-800">
                  <VideoOff className="w-6 h-6 text-gray-500" />
                </div>
              )}
            </div>
          </>
        ) : (
          /* Audio Call Layout */
          <div className="flex flex-col items-center justify-center space-y-6">
            <div className="relative">
              <div className="w-32 h-32 rounded-full bg-emerald-500/10 border-2 border-emerald-500/40 flex items-center justify-center animate-pulse">
                <Volume2 className="w-12 h-12 text-emerald-400" />
              </div>
            </div>
            <div className="text-center">
              <h2 className="text-xl font-bold font-heading text-white">{nickname}</h2>
              <p className="text-xs text-gray-400 mt-1">End-to-End Encrypted Audio Call</p>
            </div>
          </div>
        )}
      </div>

      {/* Bottom Call Control Action Bar */}
      <div className="flex items-center justify-center space-x-6 py-2 z-20">
        <button
          onClick={handleMicClick}
          className={`btn-control ${!micEnabled ? 'active-off' : ''}`}
          title={micEnabled ? 'Mute Microphone' : 'Unmute Microphone'}
        >
          {micEnabled ? <Mic className="w-5 h-5" /> : <MicOff className="w-5 h-5" />}
        </button>

        {callType === 'video' && (
          <button
            onClick={handleCamClick}
            className={`btn-control ${!camEnabled ? 'active-off' : ''}`}
            title={camEnabled ? 'Turn Off Camera' : 'Turn On Camera'}
          >
            {camEnabled ? <Video className="w-5 h-5" /> : <VideoOff className="w-5 h-5" />}
          </button>
        )}

        <button
          onClick={onLeaveCall}
          className="btn-control btn-end"
          title="Leave Call"
        >
          <PhoneOff className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
};
export default ActiveCall;
