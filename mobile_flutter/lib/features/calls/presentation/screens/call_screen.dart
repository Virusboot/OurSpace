import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/security/native_security_service.dart';
import '../../../../shared/widgets/security_overlay.dart';

class CallScreen extends StatefulWidget {
  final String callType; // 'audio' or 'video'
  final Map<String, dynamic>? recipient;
  final bool isDarkMode;
  final VoidCallback onEndCall;

  const CallScreen({
    Key? key,
    required this.callType,
    required this.recipient,
    this.isDarkMode = false,
    required this.onEndCall,
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

  @override
  void initState() {
    super.initState();
    NativeSecurityService.enableFlagSecure();
    _camEnabled = widget.callType == 'video';
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    NativeSecurityService.disableFlagSecure();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.recipient?['username'] ?? '@peer';
    final isDark = widget.isDarkMode;
    final bgCol = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final timerBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);
    final dockBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final dockBorderCol = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final avatarBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);

    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: bgCol,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Header Bar with E2E Verification & Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                        border: Border.all(color: const Color(0xFF0066FF).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.security_rounded, size: 14, color: Color(0xFF0066FF)),
                          SizedBox(width: 6),
                          Text('WebRTC P2P Encrypted', style: TextStyle(color: Color(0xFF0066FF), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Caller Avatar & Status
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Glowing Avatar Ring
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
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
                                name.length > 2 ? name.substring(0, 2).toUpperCase() : 'PEER',
                                style: TextStyle(color: txtCol, fontSize: 34, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(name, style: TextStyle(color: txtCol, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0066FF), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              widget.callType == 'video' ? 'HD Video Call Connected' : 'HD Voice Call Connected',
                              style: const TextStyle(color: Color(0xFF0066FF), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

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
                      // Mic Button
                      _buildControlButton(
                        icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                        color: _micEnabled ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFF43F5E),
                        bgColor: _micEnabled ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)) : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                        onTap: () => setState(() => _micEnabled = !_micEnabled),
                      ),

                      // Speaker Button
                      _buildControlButton(
                        icon: _speakerEnabled ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: _speakerEnabled ? const Color(0xFF0066FF) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        bgColor: _speakerEnabled ? const Color(0xFF0066FF).withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                        onTap: () => setState(() => _speakerEnabled = !_speakerEnabled),
                      ),

                      // Camera Button (Video mode only)
                      if (widget.callType == 'video')
                        _buildControlButton(
                          icon: _camEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          color: _camEnabled ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFF43F5E),
                          bgColor: _camEnabled ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)) : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                          onTap: () => setState(() => _camEnabled = !_camEnabled),
                        ),

                      // End Call Button
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
