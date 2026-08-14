import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/crypto/e2ee_crypto_service.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/security_overlay.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> recipient;
  final bool isDarkMode;
  final VoidCallback onBack;
  final Function(String type, Map<String, dynamic> recipient) onStartCall;
  final Function(String imageUri, bool isViewOnce) onOpenImageViewer;

  const ChatScreen({
    super.key,
    required this.user,
    required this.recipient,
    required this.isDarkMode,
    required this.onBack,
    required this.onStartCall,
    required this.onOpenImageViewer,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  int _ttlSeconds = 30; // default 30s
  bool _isGhostMode = false;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _checkGhostMode();
    _initChat();
    _listenToWebSockets();
  }

  Future<void> _checkGhostMode() async {
    final ghost = await SecureStorageService.read('ghost_mode_enabled');
    if (ghost == 'true') {
      setState(() {
        _isGhostMode = true;
        _ttlSeconds = 30;
      });
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _listenToWebSockets() {
    WebSocketClient().connect();
    _wsSubscription = WebSocketClient().stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'chat_receive') {
        final msg = event['message'] ?? event;
        final encrypted = msg['encryptedPayload'] ?? '';
        final text = E2EECryptoService.decryptPayload(encrypted, widget.recipient['publicKey'] ?? '');
        final newMsg = {
          'id': msg['id'] ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
          'senderId': msg['senderId'] ?? widget.recipient['id'],
          'encryptedPayload': encrypted,
          'decryptedText': text.isNotEmpty ? text : (msg['text'] ?? 'Encrypted message'),
          'time': 'Just now',
          'isTyping': false,
        };

        setState(() {
          _messages.removeWhere((m) => m['isTyping'] == true);
          _messages.add(newMsg);
        });
        _scrollToBottom();

        // Ghost Mode / TTL 30s Auto Disappear
        if (_isGhostMode || _ttlSeconds > 0) {
          final msgId = newMsg['id'];
          Timer(Duration(seconds: _ttlSeconds), () {
            if (mounted) {
              setState(() {
                _messages.removeWhere((m) => m['id'] == msgId);
              });
            }
          });
        }
      } else if (type == 'chat_typing') {
        if (event['senderId'] == widget.recipient['id']) {
          setState(() {
            _messages.removeWhere((m) => m['isTyping'] == true);
            if (event['isTyping'] == true) {
              _messages.add({
                'id': 'typing_${DateTime.now().millisecondsSinceEpoch}',
                'senderId': widget.recipient['id'],
                'decryptedText': '',
                'time': '',
                'isTyping': true,
              });
            }
          });
          _scrollToBottom();
        }
      }
    });
  }



  Future<void> _initChat() async {
    try {
      final res = await ApiClient.post('/chat/conversation', {'recipientId': widget.recipient['id'] ?? 'u2'});
      _conversationId = res['conversationId'];
      _loadMessages(_conversationId!);
    } catch (_) {}
  }

  Future<void> _loadMessages(String convId) async {
    try {
      final res = await ApiClient.get('/chat/messages/$convId');
      final rawMsgs = res['messages'] as List<dynamic>;
      if (rawMsgs.isNotEmpty) {
        final decryptedList = <Map<String, dynamic>>[];
        for (final msg in rawMsgs) {
          final text = E2EECryptoService.decryptPayload(msg['encryptedPayload'], widget.recipient['publicKey'] ?? '');
          decryptedList.add({...msg, 'decryptedText': text, 'time': '5:22'});
        }
        setState(() {
          _messages.clear();
          _messages.addAll(decryptedList);
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();

    final encrypted = E2EECryptoService.encryptPayload(text, widget.recipient['publicKey'] ?? '');
    final localMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'conversationId': _conversationId ?? 'c1',
      'senderId': widget.user['id'] ?? 'u1',
      'encryptedPayload': encrypted,
      'decryptedText': text,
      'messageType': 'text',
      'time': '5:22',
      'isTyping': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      // Remove typing indicator if present before inserting new msg
      _messages.removeWhere((m) => m['isTyping'] == true);
      _messages.add(localMsg);
    });
    _scrollToBottom();

    if (_isGhostMode || _ttlSeconds > 0) {
      final msgId = localMsg['id'];
      Timer(Duration(seconds: _ttlSeconds), () {
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == msgId);
          });
        }
      });
    }

    if (_conversationId != null) {
      WebSocketClient().send({
        'type': 'chat_send',
        'conversationId': _conversationId,
        'senderId': widget.user['id'] ?? 'u1',
        'recipientId': widget.recipient['id'] ?? 'u2',
        'encryptedPayload': encrypted,
        'messageType': 'text',
        'ttlSeconds': _ttlSeconds,
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachmentImage(ImageSource source, {bool isViewOnce = false}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
      if (picked != null) {
        widget.onOpenImageViewer(picked.path, isViewOnce);
      }
    } catch (_) {}
  }

  void _showAttachmentOptions() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Share Media Attachment', style: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF0066FF), child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
                title: Text('Take Camera Photo', style: TextStyle(color: txtColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAttachmentImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF0066FF), child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20)),
                title: Text('Choose Gallery Image', style: TextStyle(color: txtColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAttachmentImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF43F5E), child: Icon(Icons.visibility_off_rounded, color: Colors.white, size: 20)),
                title: const Text('Send View-Once Media', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
                subtitle: const Text('Recipient can view photo only once before auto-destruction', style: TextStyle(fontSize: 11, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAttachmentImage(ImageSource.gallery, isViewOnce: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimerPickerModal() {
    final isDark = widget.isDarkMode;
    final modalBg = isDark ? const Color(0xFF14161C) : const Color(0xFFFFFFFF);
    final titleTxt = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBg,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_rounded, color: Color(0xFF0066FF), size: 20),
              const SizedBox(width: 8),
              Text('Disappearing Messages Timer', style: TextStyle(color: titleTxt, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text('Messages sent after changing this timer will automatically disappear after being read.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          ...[
            {'label': 'Off', 'sec': 0},
            {'label': '10 Seconds', 'sec': 10},
            {'label': '30 Seconds', 'sec': 30},
            {'label': '1 Minute', 'sec': 60},
            {'label': '5 Minutes', 'sec': 300},
            {'label': '24 Hours', 'sec': 86400},
          ].map((opt) {
            final sec = opt['sec'] as int;
            final isSel = _ttlSeconds == sec;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(opt['label'] as String, style: TextStyle(color: isSel ? const Color(0xFF0066FF) : titleTxt, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0066FF)) : null,
              onTap: () {
                setState(() => _ttlSeconds = sec);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmClearChat() {
    final isDark = widget.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Chat History?', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to clear all messages in this conversation? This action cannot be undone.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser() {
    final isDark = widget.isDarkMode;
    final rawName = widget.recipient['username'] ?? 'User';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Block $rawName?', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Blocked contacts will no longer be able to call you or send you messages.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$rawName has been blocked'), duration: const Duration(seconds: 2), backgroundColor: const Color(0xFFF43F5E)),
              );
              widget.onBack();
            },
            child: const Text('Block', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecipientProfileModal() {
    final rawName = widget.recipient['username'] ?? 'User';
    final displayName = rawName.startsWith('@') ? 'Salina Gomez' : rawName;
    final username = rawName.startsWith('@') ? rawName : '@${rawName.toLowerCase().replaceAll(' ', '')}';
    final privateId = widget.recipient['privateId'] ?? 'USER-${widget.recipient['id'] ?? '891240'}';
    final profileImgPath = widget.recipient['profileImage'];

    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final sectionBg = isDark ? const Color(0xFF1B1D24) : const Color(0xFFF8FAFC);
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // WhatsApp Style Large Profile Avatar
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: profileImgPath == null
                    ? const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF0044B3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(color: const Color(0xFF0066FF), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: (profileImgPath != null && File(profileImgPath).existsSync())
                    ? Image.file(
                        File(profileImgPath),
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          displayName.replaceAll('@', '').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Display Name & Username
            Text(
              displayName,
              style: TextStyle(color: txtColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              username,
              style: const TextStyle(color: Color(0xFF0066FF), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Private ID Badge & Online Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    privateId,
                    style: const TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                      SizedBox(width: 5),
                      Text(
                        'Online',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // WhatsApp Style Action Bar (Audio, Video, Search)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaActionButton(
                  icon: Icons.phone_outlined,
                  label: 'Audio',
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onStartCall('audio', widget.recipient);
                  },
                ),
                _buildWaActionButton(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onStartCall('video', widget.recipient);
                  },
                ),
                _buildWaActionButton(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // WhatsApp "About" Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Hey there! I am using OurSpace Privacy Chat.', style: TextStyle(color: txtColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Available | End-to-End Encrypted', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // WhatsApp Style Security & Encryption Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End-to-End Encryption', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Messages and calls are secured with AES-256 E2EE keys. Tap to verify.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0066FF), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Color(0xFF0066FF), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawName = widget.recipient['username'] ?? 'Salina Gomez';
    final displayName = rawName.startsWith('@') ? 'Salina Gomez' : rawName;
    final isDark = widget.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final headerTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF121317) : const Color(0xFFFFFFFF);
    final peerBubbleBg = isDark ? const Color(0xFF212328) : const Color(0xFFE2E8F0);
    final peerTxtColor = isDark ? const Color(0xFFC7C9CE) : const Color(0xFF0F172A);
    final avatarBg = isDark ? const Color(0xFF26282F) : const Color(0xFFCBD5E1);
    final inputBg = isDark ? const Color(0xFF1D1F24) : const Color(0xFFEDF2F7);
    final inputTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputHint = isDark ? const Color(0xFF6C727F) : const Color(0xFF94A3B8);

    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // TOP HEADER BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 36),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconCol, size: 20),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showRecipientProfileModal,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: const Color(0xFF0066FF).withOpacity(0.12),
                              child: (widget.recipient['profileImage'] != null && File(widget.recipient['profileImage']).existsSync())
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(19),
                                      child: Image.file(
                                        File(widget.recipient['profileImage']),
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      displayName.replaceAll('@', '').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: headerTxt,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Online',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_outlined, color: Color(0xFF0066FF), size: 24),
                      onPressed: () => widget.onStartCall('audio', widget.recipient),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_outlined, color: Color(0xFF0066FF), size: 24),
                      onPressed: () => widget.onStartCall('video', widget.recipient),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: iconCol, size: 24),
                      color: isDark ? const Color(0xFF191B22) : Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            _showRecipientProfileModal();
                            break;
                          case 'timer':
                            _showTimerPickerModal();
                            break;
                          case 'clear':
                            _confirmClearChat();
                            break;
                          case 'block':
                            _confirmBlockUser();
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, color: isDark ? Colors.white70 : const Color(0xFF475569), size: 20),
                              const SizedBox(width: 12),
                              Text('View Contact Info', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'timer',
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, color: isDark ? Colors.white70 : const Color(0xFF475569), size: 20),
                              const SizedBox(width: 12),
                              Text('Disappearing Messages', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.cleaning_services_outlined, color: isDark ? Colors.white70 : const Color(0xFF475569), size: 20),
                              const SizedBox(width: 12),
                              Text('Clear Chat History', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: const Row(
                            children: [
                              Icon(Icons.block_rounded, color: Color(0xFFF43F5E), size: 20),
                              SizedBox(width: 12),
                              Text('Block Contact', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // MAIN CHAT AREA CONTAINER
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: Column(
                    children: [
                      if (_isGhostMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withOpacity(0.14),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            border: Border(bottom: BorderSide(color: const Color(0xFF0066FF).withOpacity(0.3))),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_off_rounded, color: Color(0xFF0066FF), size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '👻 GHOST MODE ACTIVE: 30s Auto-Disappear & View-Once',
                                  style: TextStyle(color: Color(0xFF0066FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, idx) {
                      final item = _messages[idx];
                      final isMe = item['senderId'] == (widget.user['id'] ?? 'u1');
                      final isTyping = item['isTyping'] == true;
                      final timeStr = item['time'] ?? '5:22';

                      if (isTyping) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: avatarBg,
                                child: Icon(Icons.person, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: peerBubbleBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: peerTxtColor, shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: peerTxtColor.withOpacity(0.7), shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: peerTxtColor.withOpacity(0.4), shape: BoxShape.circle)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: avatarBg,
                                    child: Icon(Icons.person, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF0066FF) : peerBubbleBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item['decryptedText'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : peerTxtColor,
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // STATUS ROW BELOW BUBBLE
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe) const SizedBox(width: 46),
                                const Icon(
                                  Icons.done_all_rounded,
                                  color: Color(0xFF0066FF),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Color(0xFF6C727F),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

              // BOTTOM FLOATING INPUT DOCK
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                color: cardBg,
                child: Row(
                  children: [
                    // Blue Circle '+' Button
                    GestureDetector(
                      onTap: _showAttachmentOptions,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Input Field Container
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                onSubmitted: (_) => _handleSend(),
                                style: TextStyle(color: inputTxt, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(color: inputHint, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.sentiment_satisfied_alt_rounded, color: inputHint, size: 22),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Microphone Icon on Far Right
                    IconButton(
                      icon: Icon(Icons.mic_none_rounded, color: inputHint, size: 24),
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
