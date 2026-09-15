import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class WhatsAppCameraScreen extends StatefulWidget {
  const WhatsAppCameraScreen({super.key});

  @override
  State<WhatsAppCameraScreen> createState() => _WhatsAppCameraScreenState();
}

class _WhatsAppCameraScreenState extends State<WhatsAppCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isPhotoMode = true; // true = PHOTO, false = VIDEO
  FlashMode _flashMode = FlashMode.off;
  int _recordDurationSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setupController(_cameras![_selectedCameraIndex]);
      } else {
        if (mounted) setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _setupController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Controller init error: $e');
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() => _isInitializing = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _setupController(_cameras![_selectedCameraIndex]);
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      newMode = FlashMode.always;
    } else {
      newMode = FlashMode.off;
    }
    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      debugPrint('Flash set error: $e');
    }
  }

  void _onShutterTap() async {
    if (_isPhotoMode) {
      // TAKE PHOTO
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          final file = await _controller!.takePicture();
          if (mounted) {
            Navigator.pop(context, {'path': file.path, 'isVideo': false});
          }
        } catch (e) {
          debugPrint('Take picture error: $e');
          _fallbackMockCapture(isVideo: false);
        }
      } else {
        _fallbackMockCapture(isVideo: false);
      }
    } else {
      // RECORD VIDEO
      if (_isRecording) {
        _stopRecording();
      } else {
        _startRecording();
      }
    }
  }

  void _startRecording() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordDurationSeconds = 0;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordDurationSeconds++);
        });
      } catch (e) {
        debugPrint('Start video error: $e');
        _fallbackMockCapture(isVideo: true);
      }
    } else {
      _fallbackMockCapture(isVideo: true);
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    if (_controller != null && _controller!.value.isRecordingVideo) {
      try {
        final file = await _controller!.stopVideoRecording();
        setState(() => _isRecording = false);
        if (mounted) {
          Navigator.pop(context, {'path': file.path, 'isVideo': true});
        }
      } catch (e) {
        debugPrint('Stop video error: $e');
        _fallbackMockCapture(isVideo: true);
      }
    } else {
      setState(() => _isRecording = false);
      _fallbackMockCapture(isVideo: true);
    }
  }

  void _fallbackMockCapture({required bool isVideo}) async {
    // If running on emulator without camera hardware, fallback to ImagePicker camera or gallery
    try {
      final picker = ImagePicker();
      if (isVideo) {
        final video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null && mounted) {
          Navigator.pop(context, {'path': video.path, 'isVideo': true});
        }
      } else {
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null && mounted) {
          Navigator.pop(context, {'path': image.path, 'isVideo': false});
        }
      }
    } catch (_) {}
  }

  void _openGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.pop(context, {'path': image.path, 'isVideo': false});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. LIVE CAMERA PREVIEW OR FALLBACK
            Positioned.fill(
              child: _controller != null && _controller!.value.isInitialized
                  ? CameraPreview(_controller!)
                  : Container(
                      color: const Color(0xFF0F172A),
                      child: Center(
                        child: _isInitializing
                            ? const CircularProgressIndicator(color: Color(0xFF10B981))
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 64, color: Colors.white38),
                                  SizedBox(height: 12),
                                  Text('WhatsApp Live Camera', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('Tap Shutter Button to Capture', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
            ),

            // 2. TOP TOOLBAR (CLOSE, RECORDING TIMER, FLASH)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Active Recording Timer
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordDurationSeconds),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('00:00', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),

                  // Flash Toggle Button
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off_rounded
                            : (_flashMode == FlashMode.auto ? Icons.flash_auto_rounded : Icons.flash_on_rounded),
                        color: _flashMode == FlashMode.off ? Colors.white : const Color(0xFFF59E0B),
                        size: 22,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),

            // 3. BOTTOM CONTROLS & MODE SELECTOR
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 16, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85), Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Control Icons Row: Gallery, Shutter Button, Switch Camera
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Left: Gallery Button
                        IconButton(
                          icon: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                          ),
                          onPressed: _openGallery,
                        ),

                        // Center: WhatsApp Shutter Button
                        GestureDetector(
                          onTap: _onShutterTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isRecording ? Colors.red : Colors.white,
                                width: 4,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: _isRecording ? BorderRadius.circular(12) : null,
                                color: _isPhotoMode ? const Color(0xFFE11D48) : Colors.red,
                              ),
                            ),
                          ),
                        ),

                        // Right: Switch Camera Flip Button
                        IconButton(
                          icon: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 22),
                          ),
                          onPressed: _toggleCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // WhatsApp Mode Selector Tabs (VIDEO | PHOTO)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // VIDEO TAB
                        GestureDetector(
                          onTap: () {
                            if (!_isRecording) {
                              setState(() => _isPhotoMode = false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: !_isPhotoMode ? const Color(0xFF10B981).withValues(alpha: 0.25) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'VIDEO',
                              style: TextStyle(
                                color: !_isPhotoMode ? const Color(0xFF10B981) : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // PHOTO TAB
                        GestureDetector(
                          onTap: () {
                            if (!_isRecording) {
                              setState(() => _isPhotoMode = true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isPhotoMode ? const Color(0xFF10B981).withValues(alpha: 0.25) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PHOTO',
                              style: TextStyle(
                                color: _isPhotoMode ? const Color(0xFF10B981) : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
