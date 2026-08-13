export interface SignalingMessage {
  type: string;
  callId?: string;
  targetId?: string;
  senderId?: string;
  guestId?: string;
  participantId?: string;
  sdp?: RTCSessionDescriptionInit;
  candidate?: RTCIceCandidateInit;
  callType?: 'audio' | 'video';
  nickname?: string;
  mediaState?: { audio: boolean; video: boolean };
}

export class WebRTCService {
  private ws: WebSocket | null = null;
  private peerConnection: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private remoteStream: MediaStream | null = null;
  private guestId: string = `guest_${Math.random().toString(36).substring(2, 9)}`;

  public onRemoteStream?: (stream: MediaStream) => void;
  public onConnectionStateChange?: (state: RTCPeerConnectionState) => void;
  public onSecurityAlert?: (message: string) => void;
  public onCallEnded?: () => void;

  constructor(private wsUrl: string = `ws://${window.location.host}/ws`) {}

  public async connectSocket(): Promise<void> {
    return new Promise((resolve, reject) => {
      // Adjust ws url if needed
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const host = window.location.host;
      const url = `${protocol}//${host}/ws`;

      this.ws = new WebSocket(url);

      this.ws.onopen = () => {
        // Register guest
        this.sendSignal({ type: 'guest_register', guestId: this.guestId });
        resolve();
      };

      this.ws.onerror = (err) => reject(err);

      this.ws.onmessage = async (event) => {
        try {
          const msg: SignalingMessage = JSON.parse(event.data);
          await this.handleSignalMessage(msg);
        } catch (e) {
          console.error('[WebRTCService] Error parsing signal message:', e);
        }
      };
    });
  }

  public async startLocalStream(callType: 'audio' | 'video'): Promise<MediaStream> {
    const constraints: MediaStreamConstraints = {
      audio: true,
      video: callType === 'video' ? { width: { ideal: 1280 }, height: { ideal: 720 } } : false
    };

    this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
    return this.localStream;
  }

  public async joinCallRoom(callId: string, nickname: string) {
    this.initPeerConnection(callId);
    this.sendSignal({
      type: 'call_join',
      callId,
      senderId: this.guestId,
      nickname
    });
  }

  private initPeerConnection(callId: string) {
    const configuration: RTCConfiguration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    };

    this.peerConnection = new RTCPeerConnection(configuration);

    if (this.localStream) {
      this.localStream.getTracks().forEach((track) => {
        this.peerConnection?.addTrack(track, this.localStream!);
      });
    }

    this.peerConnection.ontrack = (event) => {
      if (event.streams && event.streams[0]) {
        this.remoteStream = event.streams[0];
        if (this.onRemoteStream) {
          this.onRemoteStream(this.remoteStream);
        }
      }
    };

    this.peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        this.sendSignal({
          type: 'ice_candidate',
          callId,
          senderId: this.guestId,
          candidate: event.candidate.toJSON()
        });
      }
    };

    this.peerConnection.onconnectionstatechange = () => {
      if (this.peerConnection && this.onConnectionStateChange) {
        this.onConnectionStateChange(this.peerConnection.connectionState);
      }
    };
  }

  private async handleSignalMessage(msg: SignalingMessage) {
    switch (msg.type) {
      case 'participant_joined':
        // As guest, when host or participant joins, create SDP offer
        if (this.peerConnection) {
          const offer = await this.peerConnection.createOffer();
          await this.peerConnection.setLocalDescription(offer);
          this.sendSignal({
            type: 'call_offer',
            callId: msg.callId,
            senderId: this.guestId,
            targetId: msg.participantId,
            sdp: offer
          });
        }
        break;

      case 'call_offer':
        if (this.peerConnection && msg.sdp) {
          await this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          const answer = await this.peerConnection.createAnswer();
          await this.peerConnection.setLocalDescription(answer);
          this.sendSignal({
            type: 'call_answer',
            callId: msg.callId,
            senderId: this.guestId,
            targetId: msg.senderId,
            sdp: answer
          });
        }
        break;

      case 'call_answer':
        if (this.peerConnection && msg.sdp) {
          await this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
        }
        break;

      case 'ice_candidate':
        if (this.peerConnection && msg.candidate) {
          await this.peerConnection.addIceCandidate(new RTCIceCandidate(msg.candidate));
        }
        break;

      case 'call_ended':
        this.leaveCall();
        if (this.onCallEnded) this.onCallEnded();
        break;

      case 'security_alert':
        if (this.onSecurityAlert) this.onSecurityAlert(msg.nickname || 'Participant');
        break;
    }
  }

  public toggleAudio(enabled: boolean) {
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach(t => t.enabled = enabled);
    }
  }

  public toggleVideo(enabled: boolean) {
    if (this.localStream) {
      this.localStream.getVideoTracks().forEach(t => t.enabled = enabled);
    }
  }

  public leaveCall() {
    if (this.localStream) {
      this.localStream.getTracks().forEach(t => t.stop());
      this.localStream = null;
    }
    if (this.peerConnection) {
      this.peerConnection.close();
      this.peerConnection = null;
    }
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.sendSignal({ type: 'call_hangup', senderId: this.guestId });
      this.ws.close();
    }
  }

  private sendSignal(msg: SignalingMessage) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(msg));
    }
  }
}
