import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/security_overlay.dart';

class CallScreen extends StatefulWidget {
  final String callType; // 'audio' or 'video'
  final Map<String, dynamic>? recipient;
  final VoidCallback onEndCall;

  const CallScreen({
    Key? key,
    required this.callType,
    required this.recipient,
    required this.onEndCall,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _micEnabled = true;
  late bool _camEnabled;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _camEnabled = widget.callType == 'video';
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
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

    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF090A0F),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text('WebRTC Encrypted', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text(_formatTimer(_secondsElapsed), style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14)),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Center(
                            child: Text(
                              name.length > 2 ? name.substring(1, 3).toUpperCase() : 'PEER',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          widget.callType == 'video' ? 'Encrypted Video Call' : 'Encrypted Audio Call',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 28,
                      icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off, color: _micEnabled ? Colors.white : const Color(0xFFF43F5E)),
                      onPressed: () => setState(() => _micEnabled = !_micEnabled),
                    ),
                    if (widget.callType == 'video') ...[
                      const SizedBox(width: 24),
                      IconButton(
                        iconSize: 28,
                        icon: Icon(_camEnabled ? Icons.videocam : Icons.videocam_off, color: _camEnabled ? Colors.white : const Color(0xFFF43F5E)),
                        onPressed: () => setState(() => _camEnabled = !_camEnabled),
                      ),
                    ],
                    const SizedBox(width: 24),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFF43F5E),
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        onPressed: widget.onEndCall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
