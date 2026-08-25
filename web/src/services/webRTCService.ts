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

  constructor(private wsUrl?: string) {}

  public async connectSocket(): Promise<void> {
    return new Promise((resolve, reject) => {
      // Adjust ws url if needed
      const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const host = isLocal ? window.location.host : 'ourspace-d81w.onrender.com';
      const url = this.wsUrl || (isLocal ? `${protocol}//${host}/ws` : `wss://${host}/ws`);

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
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      },
      video: callType === 'video' ? {
        width: { ideal: 1920, min: 1280 },
        height: { ideal: 1080, min: 720 },
        frameRate: { ideal: 30 }
      } : false
    };

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (_) {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: callType === 'video' ? true : false
      });
    }
    return this.localStream;
  }

  public async joinCallRoom(callId: string, nickname: string) {
    this.callId = callId;
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
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' },
        { urls: 'stun:stun3.l.google.com:19302' },
        {
          urls: 'turn:openrelay.metered.ca:80',
          username: 'openrelayproject',
          credential: 'openrelayproject'
        },
        {
          urls: 'turn:openrelay.metered.ca:443',
          username: 'openrelayproject',
          credential: 'openrelayproject'
        },
        {
          urls: 'turn:openrelay.metered.ca:443?transport=tcp',
          username: 'openrelayproject',
          credential: 'openrelayproject'
        }
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
          targetId: this.remoteParticipantId ?? undefined,
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

  private callId: string = '';
  private hasRemoteDescription: boolean = false;
  private queuedCandidates: RTCIceCandidateInit[] = [];
  private remoteParticipantId: string | null = null;

  private async handleSignalMessage(msg: SignalingMessage) {
    switch (msg.type) {

      case 'call_joined_ack': {
        // We (guest) just joined. If host is already in room → we answer (host will send offer)
        // If room was empty → we wait for host/participant_joined event
        const existing = (msg as any).existingParticipants as string[] | undefined;
        if (existing && existing.length > 0) {
          // Host is already waiting → they will send us an offer. Nothing to do here.
          this.remoteParticipantId = existing[0];
          console.log('[WebRTC] Host already in room, waiting for their offer...');
        }
        break;
      }

      case 'participant_joined': {
        // Someone joined AFTER us. As the one already in the room, we create the offer.
        this.remoteParticipantId = msg.participantId ?? null;
        if (!this.peerConnection) {
          this.initPeerConnection(this.callId);
        }
        if (this.peerConnection && this.remoteParticipantId) {
          console.log('[WebRTC] New participant joined, creating offer...');
          const offer = await this.peerConnection.createOffer();
          await this.peerConnection.setLocalDescription(offer);
          this.sendSignal({
            type: 'call_offer',
            callId: this.callId,
            senderId: this.guestId,
            targetId: this.remoteParticipantId,
            sdp: offer
          });
        }
        break;
      }

      case 'call_offer': {
        this.remoteParticipantId = msg.senderId ?? null;
        if (!this.peerConnection) {
          this.initPeerConnection(this.callId);
        }
        if (this.peerConnection && msg.sdp) {
          this.remoteParticipantId = msg.senderId ?? null;
          await this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          this.hasRemoteDescription = true;
          const answer = await this.peerConnection.createAnswer();
          await this.peerConnection.setLocalDescription(answer);
          this.sendSignal({
            type: 'call_answer',
            callId: this.callId,
            senderId: this.guestId,
            targetId: msg.senderId,
            sdp: answer
          });
          // Flush queued ICE candidates
          await this.flushQueuedCandidates();
        }
        break;
      }

      case 'call_answer': {
        if (this.peerConnection && msg.sdp) {
          await this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          this.hasRemoteDescription = true;
          await this.flushQueuedCandidates();
        }
        break;
      }

      case 'ice_candidate': {
        if (msg.candidate) {
          if (this.peerConnection && this.hasRemoteDescription) {
            await this.peerConnection.addIceCandidate(new RTCIceCandidate(msg.candidate));
          } else {
            this.queuedCandidates.push(msg.candidate);
          }
        }
        break;
      }

      case 'call_ended':
        this.leaveCall();
        if (this.onCallEnded) this.onCallEnded();
        break;

      case 'security_alert':
        if (this.onSecurityAlert) this.onSecurityAlert(msg.nickname || 'Participant');
        break;
    }
  }

  private async flushQueuedCandidates() {
    if (!this.peerConnection) return;
    for (const c of this.queuedCandidates) {
      await this.peerConnection.addIceCandidate(new RTCIceCandidate(c));
    }
    this.queuedCandidates = [];
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
