import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/security/native_security_service.dart';
import '../../../../shared/widgets/security_overlay.dart';
import '../../../../core/networking/websocket_client.dart';

class CallScreen extends StatefulWidget {
  final String callType; // 'audio' or 'video'
  final Map<String, dynamic>? recipient;
  final String? callId;
  final Map<String, dynamic>? user;
  final bool isDarkMode;
  final VoidCallback onEndCall;
  final bool isPipMode;
  final VoidCallback? onMinimize;

  const CallScreen({
    Key? key,
    required this.callType,
    required this.recipient,
    required this.callId,
    required this.user,
    this.isDarkMode = false,
    required this.onEndCall,
    this.isPipMode = false,
    this.onMinimize,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _micEnabled = true;
  late bool _camEnabled;
  bool _speakerEnabled = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  // WebRTC members
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCPeerConnection? _peerConnection;
  StreamSubscription<Map<String, dynamic>>? _wsCallSubscription;

  String? _remoteParticipantId;
  String? _remoteParticipantName;   // updated when guest joins
  bool _isConnected = false;
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _queuedRemoteCandidates = [];

  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Free public TURN servers for strict NATs (Mobile data/Jio/Airtel)
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp'
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    NativeSecurityService.enableFlagSecure();
    _camEnabled = widget.callType == 'video';
    
    _initRenderers();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isConnected) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    await _setupLocalMedia();
    _listenToSignaling();
    _joinCallRoom();
  }

  Future<void> _setupLocalMedia() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': widget.callType == 'video'
            ? {
                'mandatory': {
                  'minWidth': '1280',
                  'minHeight': '720',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      try {
        _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      } catch (_) {
        final fallbackConstraints = <String, dynamic>{
          'audio': true,
          'video': widget.callType == 'video' ? {'facingMode': 'user'} : false,
        };
        _localStream = await navigator.mediaDevices.getUserMedia(fallbackConstraints);
      }

      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to get local media: $e');
    }
  }

  void _joinCallRoom() {
    if (widget.callId == null) return;
    
    WebSocketClient().send({
      'type': 'call_join',
      'callId': widget.callId,
      'senderId': widget.user?['id'] ?? 'user_host',
      'nickname': widget.user?['username'] ?? '@host_user',
    });
  }

  void _listenToSignaling() {
    _wsCallSubscription = WebSocketClient().stream.listen((event) async {
      if (!mounted) return;
      final type = event['type'];
      final callId = event['callId'];
      
      if (callId != widget.callId) return;

      switch (type) {
        case 'call_joined_ack':
          final existing = event['existingParticipants'] as List<dynamic>?;
          if (existing != null && existing.isNotEmpty) {
            // Room host is already waiting. Store host ID and wait for their offer.
            _remoteParticipantId = existing.first.toString();
          }
          break;

        case 'participant_joined':
          final newParticipant = event['participantId'];
          final newNickname = event['nickname']?.toString();
          if (newParticipant != widget.user?['id']) {
            setState(() {
              _remoteParticipantId = newParticipant;
              if (newNickname != null && newNickname.isNotEmpty) {
                _remoteParticipantName = newNickname;
              }
            });
            // We are the host in the room. Initiate peer connection and send offer.
            await _createPeerConnection();
            await _sendOffer();
          }
          break;

        case 'call_offer':
          _remoteParticipantId = event['senderId'];
          await _createPeerConnection();
          
          final offerSdp = event['sdp']['sdp'] ?? event['sdp'];
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(offerSdp, 'offer'),
          );
          _hasRemoteDescription = true;
          
          await _sendAnswer();
          await _processQueuedCandidates();
          break;

        case 'call_answer':
          if (_peerConnection != null) {
            final answerSdp = event['sdp']['sdp'] ?? event['sdp'];
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(answerSdp, 'answer'),
            );
            _hasRemoteDescription = true;
            await _processQueuedCandidates();
          }
          break;

        case 'ice_candidate':
          final candidateMap = event['candidate'];
          if (candidateMap != null) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            );
            
            if (_peerConnection != null && _hasRemoteDescription) {
              await _peerConnection!.addCandidate(candidate);
            } else {
              _queuedRemoteCandidates.add(candidate);
            }
          }
          break;

        case 'call_ended':
        case 'call_hangup':
          widget.onEndCall();
          break;
      }
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceConfig);

    _peerConnection!.onIceCandidate = (candidate) {
      if (_remoteParticipantId != null) {
        WebSocketClient().send({
          'type': 'ice_candidate',
          'callId': widget.callId,
          'targetId': _remoteParticipantId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteStream = event.streams[0];
          _remoteRenderer.srcObject = event.streams[0];
          _isConnected = true;
        });
      }
    };

    _peerConnection!.onAddStream = (stream) {
      setState(() {
        _remoteStream = stream;
        _remoteRenderer.srcObject = stream;
        _isConnected = true;
      });
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() => _isConnected = true);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        setState(() => _isConnected = false);
      }
    };

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }
  }

  Future<void> _sendOffer() async {
    if (_peerConnection == null) return;
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': widget.callType == 'video',
    });
    await _peerConnection!.setLocalDescription(offer);
    
    WebSocketClient().send({
      'type': 'call_offer',
      'callId': widget.callId,
      'targetId': _remoteParticipantId,
      'senderUsername': widget.user?['username'] ?? '@anonymous',
      'callType': widget.callType,
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> _sendAnswer() async {
    if (_peerConnection == null) return;
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    WebSocketClient().send({
      'type': 'call_answer',
      'callId': widget.callId,
      'targetId': _remoteParticipantId,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  Future<void> _processQueuedCandidates() async {
    if (_peerConnection == null) return;
    for (final candidate in _queuedRemoteCandidates) {
      await _peerConnection!.addCandidate(candidate);
    }
    _queuedRemoteCandidates.clear();
  }

  void _toggleMic() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        setState(() => _micEnabled = audioTrack.enabled);
      }
    }
  }

  void _toggleCam() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        setState(() => _camEnabled = videoTrack.enabled);
      }
    }
  }

  @override
  void dispose() {
    NativeSecurityService.disableFlagSecure();
    _timer?.cancel();
    _wsCallSubscription?.cancel();
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Show live name once guest joins, else placeholder
    final rawName = _remoteParticipantName ?? widget.recipient?['username'] ?? '@peer';
    final isWaitingForGuest = rawName == '@waiting_for_join';
    final name = isWaitingForGuest ? 'Waiting for guest...' : rawName;
    final isDark = widget.isDarkMode;
    final bgCol = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final timerBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);
    final dockBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final dockBorderCol = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final avatarBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);

    final showRemoteVideo = widget.callType == 'video' && _isConnected && _remoteStream != null;
    // Show own camera as fullscreen while waiting (before guest joins)
    final showLocalPreviewFullscreen = widget.callType == 'video' && !showRemoteVideo && _localStream != null;

    if (widget.isPipMode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7B2FBE), width: 2),
        ),
        child: Stack(
          children: [
            if (showRemoteVideo)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              )
            else if (showLocalPreviewFullscreen)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              )
            else
              Center(child: Icon(widget.callType == 'video' ? Icons.videocam : Icons.phone, color: Colors.white)),
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(_formatTimer(_secondsElapsed), style: const TextStyle(color: Colors.white, fontSize: 10)),
                )
              )
            ),
          ]
        )
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (widget.onMinimize != null) {
          widget.onMinimize!();
        } else {
          widget.onEndCall();
        }
      },
      child: SecurityOverlay(
        isSensitive: true,
        child: Scaffold(
        backgroundColor: bgCol,
        body: SafeArea(
          child: Stack(
            children: [
              // Own camera as fullscreen background while waiting for guest
              if (showLocalPreviewFullscreen)
                Positioned.fill(
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

              // Remote video stream covers full background once connected
              if (showRemoteVideo)
                Positioned.fill(
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

              // UI Overlay
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FBE).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.security_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('WebRTC P2P Encrypted', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: timerBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimer(_secondsElapsed),
                                style: TextStyle(color: txtCol, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (widget.onMinimize != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: widget.onMinimize,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.picture_in_picture_alt_rounded, size: 18, color: txtCol),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),


                    // Avatar overlay: shown for audio call OR when video not yet connected
                    if (!showRemoteVideo)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Only show avatar when NOT showing local camera fullscreen
                              if (!showLocalPreviewFullscreen) ...[
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7B2FBE), Color(0xFF0052CC)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: avatarBg,
                                      child: Text(
                                        name.length > 2 ? name.substring(0, 2).toUpperCase() : '?',
                                        style: TextStyle(color: txtCol, fontSize: 34, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Name + status pill — always shown as overlay on camera
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: showLocalPreviewFullscreen ? 0.45 : 0.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: showLocalPreviewFullscreen ? Colors.white : txtCol,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        shadows: showLocalPreviewFullscreen
                                            ? [const Shadow(color: Colors.black54, blurRadius: 6)]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isWaitingForGuest)
                                          const SizedBox(
                                            width: 10, height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Color(0xFF7B2FBE),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _isConnected ? Colors.green : const Color(0xFF7B2FBE),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isConnected
                                              ? 'HD Call Connected'
                                              : isWaitingForGuest
                                                  ? 'Share the link to invite'
                                                  : (widget.callType == 'video' ? 'Connecting Video Call...' : 'Connecting Voice Call...'),
                                          style: TextStyle(
                                            color: showLocalPreviewFullscreen
                                                ? Colors.white70
                                                : const Color(0xFF7B2FBE),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            shadows: showLocalPreviewFullscreen
                                                ? [const Shadow(color: Colors.black54, blurRadius: 4)]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    // Floating Controls Dock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: dockBg,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: dockBorderCol),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                            color: _micEnabled ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFF43F5E),
                            bgColor: _micEnabled ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)) : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                            onTap: _toggleMic,
                          ),
                          _buildControlButton(
                            icon: _speakerEnabled ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            color: _speakerEnabled ? const Color(0xFF7B2FBE) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            bgColor: _speakerEnabled ? const Color(0xFF7B2FBE).withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                            onTap: () => setState(() => _speakerEnabled = !_speakerEnabled),
                          ),
                          if (widget.callType == 'video')
                            _buildControlButton(
                              icon: _camEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                              color: _camEnabled ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFF43F5E),
                              bgColor: _camEnabled ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)) : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                              onTap: _toggleCam,
                            ),
                          GestureDetector(
                            onTap: widget.onEndCall,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

              // PiP local video — shown only when REMOTE is streaming (guest connected)
              if (showRemoteVideo && _camEnabled)
                Positioned(
                  right: 16,
                  top: 80,
                  width: 100,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white38, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
