import 'package:flutter/material.dart';
import '../../core/security/native_security_service.dart';

class SecurityOverlay extends StatefulWidget {
  final Widget child;
  final bool isSensitive;

  const SecurityOverlay({
    super.key,
    required this.child,
    this.isSensitive = true,
  });

  @override
  State<SecurityOverlay> createState() => _SecurityOverlayState();
}

class _SecurityOverlayState extends State<SecurityOverlay> with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isSensitive) {
      NativeSecurityService.enableFlagSecure();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.isSensitive) {
      setState(() {
        _isBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBackground)
          Container(
            color: const Color(0xFF090A0F),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 54, color: Color(0xFF7B2FBE)),
                  SizedBox(height: 16),
                  Text(
                    'Protected View',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Privacy lock active while app is in background.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
