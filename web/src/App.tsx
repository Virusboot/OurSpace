import React, { useEffect, useState } from 'react';
import { LandingJoin } from './components/LandingJoin';
import { ActiveCall } from './components/ActiveCall';
import { ExpiredLink, InvalidLink } from './components/ExpiredLink';
import { WebHome } from './components/WebHome';
import { WebLogin } from './components/WebLogin';
import { PrivacyPolicy } from './components/PrivacyPolicy';
import { TermsConditions } from './components/TermsConditions';
import { ContactUs } from './components/ContactUs';
import { AboutUs } from './components/AboutUs';
import { WebProfile } from './components/WebProfile';
import { WebRTCService } from './services/webRTCService';

const API_BASE = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
  ? '' 
  : 'https://ourspace-d81w.onrender.com';

export const App: React.FC = () => {
  const [currentRoute, setCurrentRoute] = useState<string>('');
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [linkDetails, setLinkDetails] = useState<any>(null);
  const [errorStatus, setErrorStatus] = useState<'expired' | 'invalid' | null>(null);
  const [pinRequired, setPinRequired] = useState(false);
  const [joinError, setJoinError] = useState<string | undefined>();

  const [inCall, setInCall] = useState(false);
  const [nickname, setNickname] = useState('');
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [remoteStream, setRemoteStream] = useState<MediaStream | null>(null);
  const [connectionState, setConnectionState] = useState('connecting');
  const [securityAlert, setSecurityAlert] = useState<string | null>(null);
  const [globalPrivacyShield, setGlobalPrivacyShield] = useState(false);

  const [rtcService] = useState(() => new WebRTCService());

  // Global Web Anti-Screenshot, Anti-Copy & Focus Shield
  useEffect(() => {
    const activateShield = () => {
      setGlobalPrivacyShield(true);
      if (inCall) {
        rtcService.sendSecurityAlert('Screenshot / Screen Capture attempt detected on Web');
      }
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      const isMacShot = (e.metaKey || e.ctrlKey) && e.shiftKey && ['3', '4', '5', 's'].includes(key);
      const isPrintScreen = key === 'printscreen' || key === 'prtscr' || key === 'sysreq';
      const isCtrlPS = (e.ctrlKey || e.metaKey) && (key === 'p' || key === 's');
      if (isPrintScreen || isMacShot || isCtrlPS) {
        e.preventDefault();
        activateShield();
        setTimeout(() => setGlobalPrivacyShield(false), 2500);
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'printscreen') {
        try { navigator.clipboard?.writeText(''); } catch (_) {}
        activateShield();
        setTimeout(() => setGlobalPrivacyShield(false), 2500);
      }
    };

    const handleContextMenu = (e: MouseEvent) => e.preventDefault();
    const handleDragStart = (e: DragEvent) => e.preventDefault();
    const handleVisibility = () => {
      if (document.hidden) activateShield();
      else setTimeout(() => setGlobalPrivacyShield(false), 400);
    };
    const handleBlur = () => activateShield();
    const handleFocus = () => setTimeout(() => setGlobalPrivacyShield(false), 300);

    window.addEventListener('keydown', handleKeyDown, true);
    window.addEventListener('keyup', handleKeyUp, true);
    document.addEventListener('contextmenu', handleContextMenu);
    document.addEventListener('dragstart', handleDragStart);
    document.addEventListener('visibilitychange', handleVisibility);
    window.addEventListener('blur', handleBlur);
    window.addEventListener('focus', handleFocus);

    return () => {
      window.removeEventListener('keydown', handleKeyDown, true);
      window.removeEventListener('keyup', handleKeyUp, true);
      document.removeEventListener('contextmenu', handleContextMenu);
      document.removeEventListener('dragstart', handleDragStart);
      document.removeEventListener('visibilitychange', handleVisibility);
      window.removeEventListener('blur', handleBlur);
      window.removeEventListener('focus', handleFocus);
    };
  }, [inCall, rtcService]);

  useEffect(() => {
    // Parse route path
    const path = window.location.pathname;
    setCurrentRoute(path);

    let urlToken: string | null = null;
    if (path.startsWith('/c/')) {
      urlToken = path.split('/c/')[1];
    } else {
      const search = new URLSearchParams(window.location.search);
      urlToken = search.get('token');
    }

    if (!urlToken) {
      setLoading(false);
      return;
    }

    setToken(urlToken);
    resolveToken(urlToken);
  }, []);

  const resolveToken = async (tok: string, pin?: string) => {
    try {
      const res = await fetch(`${API_BASE}/api/call-links/resolve/${tok}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin })
      });

      const data = await res.json();
      if (!res.ok) {
        if (data.error === 'PIN_REQUIRED') {
          setPinRequired(true);
          setLoading(false);
          return;
        }
        if (data.error && data.error.includes('expired')) {
          setErrorStatus('expired');
        } else {
          setErrorStatus('invalid');
        }
        setLoading(false);
        return;
      }

      setLinkDetails(data);
      setPinRequired(false);
      setLoading(false);
      return data;
    } catch (err: any) {
      setErrorStatus('invalid');
      setLoading(false);
    }
  };

  const handleJoin = async (guestNickname: string, pin?: string) => {
    setJoinError(undefined);
    let details = linkDetails;
    if (!details) {
      details = await resolveToken(token!, pin);
    }

    if (!details || !details.callId) {
      setJoinError('Invalid or expired call link credentials.');
      return;
    }

    try {
      setNickname(guestNickname);
      await rtcService.connectSocket();
      const stream = await rtcService.startLocalStream(details.callType || 'video');
      setLocalStream(stream);

      rtcService.onRemoteStream = (rStream) => {
        setRemoteStream(rStream);
      };

      rtcService.onConnectionStateChange = (state) => {
        setConnectionState(state);
      };

      rtcService.onSecurityAlert = (alertMsg) => {
        setSecurityAlert(alertMsg);
        setTimeout(() => setSecurityAlert(null), 8000);
      };

      rtcService.onCallEnded = () => {
        setInCall(false);
        setLocalStream(null);
        setRemoteStream(null);
        setErrorStatus('expired');
      };

      await rtcService.joinCallRoom(details.callId, guestNickname);
      setInCall(true);
    } catch (err: any) {
      setJoinError(err.message || 'Failed to access camera/microphone');
    }
  };

  const handleLeaveCall = () => {
    rtcService.leaveCall();
    setInCall(false);
    setLocalStream(null);
    setRemoteStream(null);
  };

  const renderRoute = () => {
    if (loading) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-black text-white">
          <div className="w-8 h-8 rounded-full border-2 border-emerald-500 border-t-transparent animate-spin"></div>
        </div>
      );
    }

    if (currentRoute === '/privacy') return <PrivacyPolicy />;
    if (currentRoute === '/terms') return <TermsConditions />;
    if (currentRoute === '/contact') return <ContactUs />;
    if (currentRoute === '/about') return <AboutUs />;
    if (currentRoute === '/profile') return <WebProfile />;
    if (currentRoute === '/login') {
      const returnPath = new URLSearchParams(window.location.search).get('return') || '/';
      return <WebLogin returnTo={returnPath} />;
    }

    if (!token) return <WebHome />;
    if (errorStatus === 'expired') return <ExpiredLink />;
    if (errorStatus === 'invalid') return <InvalidLink />;

    if (inCall) {
      return (
        <ActiveCall
          callType={linkDetails?.callType || 'video'}
          localStream={localStream}
          remoteStream={remoteStream}
          nickname={nickname}
          connectionState={connectionState}
          securityAlert={securityAlert}
          onToggleMic={(enabled) => rtcService.toggleAudio(enabled)}
          onToggleCam={(enabled) => rtcService.toggleVideo(enabled)}
          onLeaveCall={handleLeaveCall}
          onSecurityEvent={(event) => rtcService.sendSecurityAlert(event)}
        />
      );
    }

    return (
      <LandingJoin
        token={token}
        callType={linkDetails?.callType || 'video'}
        pinRequired={pinRequired}
        onJoin={handleJoin}
        errorMsg={joinError}
      />
    );
  };

  return (
    <>
      {renderRoute()}
      {globalPrivacyShield && (
        <div className="fixed inset-0 z-[9999] bg-black/95 backdrop-blur-xl flex flex-col items-center justify-center text-white select-none">
          <div className="w-14 h-14 rounded-2xl bg-purple-600/20 border border-purple-500/40 flex items-center justify-center mb-4">
            <span className="text-2xl">🛡️</span>
          </div>
          <p className="text-lg font-bold">OurSpace Privacy Shield Active</p>
          <p className="text-xs text-slate-400 mt-1">Screen protected against background capture &amp; screenshots</p>
        </div>
      )}
    </>
  );
};
export default App;
