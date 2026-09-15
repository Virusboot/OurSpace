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
        if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
          _isBackground = true;
        } else {
          _isBackground = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBackground)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
            ),
          ),
      ],
    );
  }
}
