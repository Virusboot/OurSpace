import 'package:flutter/material.dart';
import '../../../../core/crypto/e2ee_crypto_service.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../shared/widgets/security_overlay.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> recipient;
  final VoidCallback onBack;
  final Function(String type, Map<String, dynamic> recipient) onStartCall;
  final Function(String imageUri, bool isViewOnce) onOpenImageViewer;

  const ChatScreen({
    super.key,
    required this.user,
    required this.recipient,
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

  @override
  void initState() {
    super.initState();
    _initChat();
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
      final decryptedList = <Map<String, dynamic>>[];
      for (final msg in rawMsgs) {
        final text = E2EECryptoService.decryptPayload(msg['encryptedPayload'], widget.recipient['publicKey'] ?? '');
        decryptedList.add({...msg, 'decryptedText': text});
      }
      setState(() {
        _messages.clear();
        _messages.addAll(decryptedList);
      });
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
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() => _messages.add(localMsg));

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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141824),
      barrierColor: Colors.black.withOpacity(0.7),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text('Disappearing Messages Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
              title: Text(opt['label'] as String, style: TextStyle(color: isSel ? const Color(0xFF10B981) : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)) : null,
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
    final username = widget.recipient['username'] ?? '@peer';

    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0D14),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: widget.onBack,
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                    child: Text(
                      username.length > 2 ? username.substring(1, 3).toUpperCase() : 'PEER',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0A0D14), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('End-to-End Encrypted', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.phone_outlined, color: Color(0xFF10B981), size: 22),
              onPressed: () => widget.onStartCall('audio', widget.recipient),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Color(0xFF10B981), size: 22),
              onPressed: () => widget.onStartCall('video', widget.recipient),
            ),
            GestureDetector(
              onTap: _showTimerPickerModal,
              child: Container(
                margin: const EdgeInsets.only(right: 14, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      _ttlSeconds == 0 ? 'Off' : '${_ttlSeconds}s',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // WhatsApp Style Security Banner Notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Messages are end-to-end encrypted. No one outside of this chat can read them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Message History List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final item = _messages[idx];
                  final isMe = item['senderId'] == (widget.user['id'] ?? 'u1');
                  final nowTime = TimeOfDay.now().format(context);

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !isMe ? const Color(0xFF141824) : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['decryptedText'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nowTime,
                                style: TextStyle(
                                  color: isMe ? Colors.black54 : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all_rounded, size: 14, color: Colors.black),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // WhatsApp Style Input Dock Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141824),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
                      onPressed: () {
                        widget.onOpenImageViewer('https://via.placeholder.com/400', true);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type encrypted message...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0A0D14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.send_rounded, color: Colors.black, size: 20),
                        ),
                      ),
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
