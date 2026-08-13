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
    if (text.isEmpty || _conversationId == null) return;
    _inputCtrl.clear();

    final encrypted = E2EECryptoService.encryptPayload(text, widget.recipient['publicKey'] ?? '');
    final localMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'conversationId': _conversationId,
      'senderId': widget.user['id'] ?? 'u1',
      'encryptedPayload': encrypted,
      'decryptedText': text,
      'messageType': 'text',
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() => _messages.add(localMsg));

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

  void _showTimerPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12141D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Disappearing Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...[
            {'label': 'Off', 'sec': 0},
            {'label': '10 Seconds', 'sec': 10},
            {'label': '30 Seconds', 'sec': 30},
            {'label': '1 Minute', 'sec': 60},
            {'label': '5 Minutes', 'sec': 300},
            {'label': '1 Hour', 'sec': 3600},
            {'label': '24 Hours', 'sec': 86400},
          ].map((opt) {
            final sec = opt['sec'] as int;
            return ListTile(
              title: Text(opt['label'] as String, style: TextStyle(color: _ttlSeconds == sec ? const Color(0xFF10B981) : Colors.grey)),
              trailing: _ttlSeconds == sec ? const Icon(Icons.check, color: Color(0xFF10B981)) : null,
              onTap: () {
                setState(() => _ttlSeconds = sec);
                Navigator.pop(ctx);
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecurityOverlay(
      isSensitive: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF090A0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090A0F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.recipient['username'] ?? '@peer', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const Row(
                children: [
                  Icon(Icons.shield, size: 10, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('End-to-End Encrypted', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.phone_outlined, color: Color(0xFF10B981)), onPressed: () => widget.onStartCall('audio', widget.recipient)),
            IconButton(icon: const Icon(Icons.videocam_outlined, color: Color(0xFF10B981)), onPressed: () => widget.onStartCall('video', widget.recipient)),
            InkWell(
              onTap: _showTimerPickerModal,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text('${_ttlSeconds}s', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final item = _messages[idx];
                  final isMe = item['senderId'] == (widget.user['id'] ?? 'u1');
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF059669) : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item['decryptedText'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type encrypted message...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF10B981),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 18),
                      onPressed: _handleSend,
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
}
