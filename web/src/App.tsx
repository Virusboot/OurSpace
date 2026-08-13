import React, { useEffect, useState } from 'react';
import { LandingJoin } from './components/LandingJoin';
import { ActiveCall } from './components/ActiveCall';
import { ExpiredLink, InvalidLink } from './components/ExpiredLink';
import { WebRTCService } from './services/webRTCService';

export const App: React.FC = () => {
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

  const [rtcService] = useState(() => new WebRTCService());

  useEffect(() => {
    // Parse call token from location path: /c/:token or query ?token=
    const path = window.location.pathname;
    let urlToken: string | null = null;
    if (path.startsWith('/c/')) {
      urlToken = path.split('/c/')[1];
    } else {
      const search = new URLSearchParams(window.location.search);
      urlToken = search.get('token');
    }

    if (!urlToken) {
      setLoading(false);
      setErrorStatus('invalid');
      return;
    }

    setToken(urlToken);
    resolveToken(urlToken);
  }, []);

  const resolveToken = async (tok: string, pin?: string) => {
    try {
      const res = await fetch(`/api/call-links/resolve/${tok}`, {
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
    if (pinRequired && pin) {
      const details = await resolveToken(token!, pin);
      if (!details) {
        setJoinError('Invalid call PIN');
        return;
      }
    }

    try {
      setNickname(guestNickname);
      await rtcService.connectSocket();
      const stream = await rtcService.startLocalStream(linkDetails?.callType || 'video');
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
      };

      await rtcService.joinCallRoom(linkDetails.callId, guestNickname);
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

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-black text-white">
        <div className="w-8 h-8 rounded-full border-2 border-emerald-500 border-t-transparent animate-spin"></div>
      </div>
    );
  }

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
      />
    );
  }

  return (
    <LandingJoin
      callType={linkDetails?.callType || 'video'}
      pinRequired={pinRequired}
      onJoin={handleJoin}
      errorMsg={joinError}
    />
  );
};
export default App;
