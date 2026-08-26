import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/notifications/notification_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerUsername;
  final String callType; // 'audio' or 'video'
  final String senderId;
  final String? senderProfileImage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.callerUsername,
    required this.callType,
    required this.senderId,
    this.senderProfileImage,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _ringTimer;

  Widget _buildAvatarImage(String? imageSource, {double size = 130, required String fallbackName}) {
    if (imageSource != null && imageSource.isNotEmpty) {
      if (imageSource.startsWith('data:image')) {
        try {
          final base64Data = imageSource.split(',').last;
          final bytes = base64Decode(base64Data);
          return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
        } catch (_) {}
      } else if (imageSource.length > 80 && !imageSource.contains('/') && !imageSource.startsWith('http')) {
        try {
          final bytes = base64Decode(imageSource);
          return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
        } catch (_) {}
      } else if (imageSource.startsWith('http')) {
        return Image.network(imageSource, width: size, height: size, fit: BoxFit.cover);
      } else if (File(imageSource).existsSync()) {
        return Image.file(File(imageSource), width: size, height: size, fit: BoxFit.cover);
      }
    }
    final clean = fallbackName.replaceAll('@', '').trim();
    final initial = clean.isNotEmpty ? clean[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startRingingFeedback();
  }

  void _startRingingFeedback() async {
    _stopRingingFeedback();
    
    // Check if device supports vibration with pattern
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Telegram/WhatsApp call pattern: repeat vibrate 1000ms, pause 1000ms
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    } else {
      HapticFeedback.vibrate();
    }

    _ringTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      SystemSound.play(SystemSoundType.click);
    });
  }

  void _stopRingingFeedback() {
    _ringTimer?.cancel();
    _ringTimer = null;
    Vibration.cancel();
  }

  void _handleAccept() async {
    _stopRingingFeedback();
    NotificationService().cancelNotification(999);

    try {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }
      if (widget.callType == 'video') {
        var camStatus = await Permission.camera.status;
        if (!camStatus.isGranted) {
          await Permission.camera.request();
        }
      }
    } catch (_) {}

    widget.onAccept();
  }

  void _handleDecline() {
    _stopRingingFeedback();
    NotificationService().cancelNotification(999);
    WebSocketClient().send({
      'type': 'call_hangup',
      'callId': widget.callId,
      'targetId': widget.senderId,
    });
    widget.onDecline();
  }

  @override
  void dispose() {
    _stopRingingFeedback();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext meCtx) {
    final cleanName = widget.callerUsername.startsWith('@')
        ? widget.callerUsername
        : '@${widget.callerUsername}';

    final initialLetter = cleanName.length > 1
        ? cleanName[1].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Call Type Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.callType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.phone_rounded,
                  color: const Color(0xFFA855F7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'OURSPACE ${widget.callType.toUpperCase()} CALL',
                  style: const TextStyle(
                    color: Color(0xFFA855F7),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Pulsing Avatar Container (WhatsApp / Telegram style)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.25);
                final opacity = 1.0 - _pulseController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow Ring 2
                    Transform.scale(
                      scale: scale * 1.2,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7B2FBE).withValues(alpha: opacity * 0.2),
                        ),
                      ),
                    ),
                    // Outer Pulsing Glow Ring 1
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7B2FBE).withValues(alpha: opacity * 0.4),
                        ),
                      ),
                    ),
                    // Avatar Circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFFC084FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x667B2FBE),
                            blurRadius: 25,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(65),
                        child: _buildAvatarImage(
                          widget.senderProfileImage,
                          size: 130,
                          fallbackName: widget.callerUsername,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 36),

            // Caller Name
            Text(
              cleanName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Incoming call...',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),

            const Spacer(),

            // Action Buttons Row (Decline vs Accept)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _handleDecline,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF4444),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Accept Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _handleAccept,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF22C55E),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6622C55E),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.callType == 'video'
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
