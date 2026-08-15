import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/crypto/e2ee_crypto_service.dart';
import '../../../../core/security/native_security_service.dart';
import '../../../../shared/widgets/security_overlay.dart';

class SecureImageViewerScreen extends StatefulWidget {
  final String imageUri;
  final bool isViewOnce;
  final bool isDarkMode;
  final VoidCallback onClose;

  const SecureImageViewerScreen({
    Key? key,
    required this.imageUri,
    required this.isViewOnce,
    this.isDarkMode = false,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SecureImageViewerScreen> createState() => _SecureImageViewerScreenState();
}

class _SecureImageViewerScreenState extends State<SecureImageViewerScreen> {
  Uint8List? _inMemoryBuffer;

  @override
  void initState() {
    super.initState();
    NativeSecurityService.enableFlagSecure();
    // Simulate loading image bytes into memory buffer
    _inMemoryBuffer = Uint8List.fromList(widget.imageUri.codeUnits);
  }

  @override
  void dispose() {
    NativeSecurityService.disableFlagSecure();
    // Explicitly zeroize memory buffer before disposal
    if (_inMemoryBuffer != null) {
      E2EECryptoService.wipeBuffer(_inMemoryBuffer!);
      _inMemoryBuffer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgCol = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final txtCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtxtCol = isDark ? Colors.grey : const Color(0xFF64748B);

    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: bgCol,
        appBar: AppBar(
          backgroundColor: bgCol,
          elevation: 0,
          title: Text(widget.isViewOnce ? 'View Once Image' : 'Protected Image', style: const TextStyle(color: Color(0xFF0066FF), fontSize: 14)),
          leading: IconButton(
            icon: Icon(Icons.close, color: txtCol),
            onPressed: widget.onClose,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF0066FF)),
                const SizedBox(height: 16),
                Text('Secure Image Viewer', style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Saving, downloading, forwarding & screenshots are restricted on supported devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtxtCol, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
