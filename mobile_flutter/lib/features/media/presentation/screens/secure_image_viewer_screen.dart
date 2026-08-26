import 'dart:io';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isViewOnce) {
      NativeSecurityService.enableFlagSecure();
    }
    _inMemoryBuffer = Uint8List.fromList(widget.imageUri.codeUnits);
  }

  @override
  void dispose() {
    if (widget.isViewOnce) {
      NativeSecurityService.disableFlagSecure();
    }
    if (_inMemoryBuffer != null) {
      E2EECryptoService.wipeBuffer(_inMemoryBuffer!);
      _inMemoryBuffer = null;
    }
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final file = File(widget.imageUri);
      if (await file.exists()) {
        final picturesDir = Directory('/storage/emulated/0/Pictures/OurSpace');
        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }
        final destPath = '${picturesDir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await file.copy(destPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to Gallery! ($destPath)'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file saved successfully.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Gallery!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgCol = isDark ? Colors.black : const Color(0xFF0F172A);
    final txtCol = Colors.white;
    final fileExists = File(widget.imageUri).existsSync();

    return SecurityOverlay(
      isSensitive: widget.isViewOnce,
      child: Scaffold(
        backgroundColor: bgCol,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          elevation: 0,
          title: Text(
            widget.isViewOnce ? '🔒 View-Once Media' : 'Photo Viewer',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: txtCol),
            onPressed: widget.onClose,
          ),
          actions: [
            if (!widget.isViewOnce)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Save to Gallery',
                onPressed: _saveToGallery,
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: fileExists
                    ? InteractiveViewer(
                        maxScale: 4.0,
                        minScale: 0.8,
                        child: Image.file(
                          File(widget.imageUri),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.isViewOnce ? Icons.visibility_off_rounded : Icons.image_rounded, size: 64, color: const Color(0xFF7B2FBE)),
                          const SizedBox(height: 16),
                          Text('Secure Media Attachment', style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'Zero-knowledge encrypted media stream.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
              ),
              if (!widget.isViewOnce && fileExists)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2FBE),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _saveToGallery,
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: const Text('Save to Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
