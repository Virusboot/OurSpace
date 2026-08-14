import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/crypto/e2ee_crypto_service.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
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
  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  int _ttlSeconds = 30; // default 30s
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSampleMessages();
    _initChat();
    _listenToWebSockets();
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

        setState(() {
          _messages.removeWhere((m) => m['isTyping'] == true);
          _messages.add({
            'id': msg['id'] ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
            'senderId': msg['senderId'] ?? widget.recipient['id'],
            'encryptedPayload': encrypted,
            'decryptedText': text.isNotEmpty ? text : (msg['text'] ?? 'Encrypted message'),
            'time': 'Just now',
            'isTyping': false,
          });
        });
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
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _loadSampleMessages() {
    _messages.addAll([
      {
        'id': 'm1',
        'senderId': widget.recipient['id'] ?? 'u2',
        'decryptedText': 'Hi! I am waiting for you',
        'time': '5:22',
        'isTyping': false,
      },
      {
        'id': 'm2',
        'senderId': widget.user['id'] ?? 'u1',
        'decryptedText': 'Have you done it?',
        'time': '5:22',
        'isTyping': false,
      },
      {
        'id': 'm3',
        'senderId': widget.recipient['id'] ?? 'u2',
        'decryptedText': 'Nop! just looking at it 😁😂',
        'time': '5:22',
        'isTyping': false,
      },
      {
        'id': 'm4',
        'senderId': widget.user['id'] ?? 'u1',
        'decryptedText': 'Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s,',
        'time': '5:22',
        'isTyping': false,
      },
      {
        'id': 'm5',
        'senderId': widget.recipient['id'] ?? 'u2',
        'decryptedText': '',
        'time': '5:22',
        'isTyping': true,
      },
    ]);
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: iconCol, size: 24),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: headerTxt,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C727F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                    IconButton(
                      icon: const Icon(Icons.timer_outlined, color: Color(0xFF0066FF), size: 22),
                      onPressed: _showTimerPickerModal,
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
                  child: ListView.builder(
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
              ),

              // BOTTOM FLOATING INPUT DOCK
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                color: cardBg,
                child: Row(
                  children: [
                    // Blue Circle '+' Button
                    GestureDetector(
                      onTap: () {
                        widget.onOpenImageViewer('https://via.placeholder.com/400', true);
                      },
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
