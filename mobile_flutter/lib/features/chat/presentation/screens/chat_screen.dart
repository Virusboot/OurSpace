import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/crypto/e2ee_crypto_service.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/security_overlay.dart';
import 'whatsapp_camera_screen.dart';

import '../../../../core/security/native_security_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> recipient;
  final bool isDarkMode;
  final VoidCallback onBack;
  final Function(String type, Map<String, dynamic> recipient, {String? callId}) onStartCall;
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
  int _ttlSeconds = 0; // 0 = permanent (no disappearance), 30s only when Ghost Mode is ON
  bool _isGhostMode = false;
  bool _isPeerOnline = false;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  void _checkPeerOnlineStatus() async {
    final initialOnline = widget.recipient['isOnline'] == true || widget.recipient['status'] == 'online';
    if (initialOnline && mounted) {
      setState(() => _isPeerOnline = true);
    }
    try {
      final dynamic res = await ApiClient.get('/users/online');
      if (res is List) {
        final List onlineList = res;
        final recipientId = widget.recipient['id']?.toString();
        final recipientUname = widget.recipient['username']?.toString().replaceAll('@', '');
        final isOnlineNow = onlineList.any((u) {
          final uMap = Map<String, dynamic>.from(u as Map);
          final uid = uMap['id']?.toString();
          final uname = uMap['username']?.toString().replaceAll('@', '');
          return (recipientId != null && uid == recipientId) || (recipientUname != null && uname == recipientUname);
        });
        if (mounted) {
          setState(() {
            _isPeerOnline = isOnlineNow;
          });
        }
      }
    } catch (_) {}
  }


  bool _isRecordingVoice = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordPath;
  String? _playingMsgId;

  Future<void> _startVoiceRecording() async {
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice notes.'),
              backgroundColor: Color(0xFFF43F5E),
            ),
          );
        }
        return;
      }
      final recPath = '${Directory.systemTemp.path}/ourspace_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
        path: recPath,
      );
      _currentRecordPath = recPath;
    } catch (e) {
      debugPrint('Voice recorder start error: $e');
    }

    if (!mounted) return;
    setState(() {
      _isRecordingVoice = true;
      _recordSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecordingVoice) {
        setState(() {
          _recordSeconds++;
        });
      }
    });
  }

  Future<void> _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
      if (_currentRecordPath != null && File(_currentRecordPath!).existsSync()) {
        await File(_currentRecordPath!).delete();
      }
    } catch (_) {}
    _currentRecordPath = null;
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordSeconds = 0;
      });
    }
  }

  void _persistMessagesCache() {
    final convId = _conversationId;
    final recipientId = widget.recipient['id']?.toString();
    // Strip huge base64 strings from SecureStorage cache so UI & Keystore stay fast;
    // local file paths (ourspace_img_*) stay intact and load instantaneously.
    final compactList = _messages.where((m) => m['isTyping'] != true).map((m) {
      final copy = Map<String, dynamic>.from(m);
      final mp = copy['mediaPath']?.toString() ?? '';
      if (mp.startsWith('data:image') && mp.length > 2000) {
        copy['mediaPath'] = '';
      }
      return copy;
    }).toList();
    final encoded = jsonEncode(compactList);
    if (convId != null && convId.isNotEmpty) {
      unawaited(SecureStorageService.write('conv_msgs_$convId', encoded));
    }
    if (recipientId != null && recipientId.isNotEmpty) {
      unawaited(SecureStorageService.write('conv_msgs_user_$recipientId', encoded));
    }
  }

  Future<String> _saveIncomingMediaToFile(String msgId, String rawMediaPath) async {
    if (rawMediaPath.startsWith('data:image')) {
      try {
        final bytes = base64Decode(rawMediaPath.split(',').last);
        final file = File('${Directory.systemTemp.path}/ourspace_img_$msgId.jpg');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (_) {}
    } else if (rawMediaPath.startsWith('data:audio')) {
      try {
        final bytes = base64Decode(rawMediaPath.split(',').last);
        final file = File('${Directory.systemTemp.path}/ourspace_voice_$msgId.m4a');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (_) {}
    }
    return rawMediaPath;
  }

  void _sendVoiceNote() async {
    _recordTimer?.cancel();
    String? stoppedPath;
    try {
      stoppedPath = await _audioRecorder.stop();
    } catch (_) {}
    final recordedFilePath = stoppedPath ?? _currentRecordPath;
    _currentRecordPath = null;

    final duration = _recordSeconds > 0 ? _recordSeconds : 1;
    final mins = duration ~/ 60;
    final secs = (duration % 60).toString().padLeft(2, '0');
    final timeFormatted = '$mins:$secs';
    final voiceText = '🎵 Voice Message ($timeFormatted)';

    setState(() {
      _isRecordingVoice = false;
      _recordSeconds = 0;
    });

    String base64Audio = '';
    if (recordedFilePath != null && File(recordedFilePath).existsSync()) {
      try {
        final bytes = await File(recordedFilePath).readAsBytes();
        base64Audio = 'data:audio/mp4;base64,${base64Encode(bytes)}';
      } catch (_) {}
    }

    if (_conversationId == null || _conversationId!.isEmpty) {
      try {
        final res = await ApiClient.post('/chat/conversation', {'recipientId': widget.recipient['id'] ?? 'u2'});
        _conversationId = res['conversationId'];
      } catch (_) {}
    }
    final activeConvId = (_conversationId != null && _conversationId!.isNotEmpty)
        ? _conversationId!
        : 'c_${widget.recipient['id'] ?? 'peer'}';

    final clientMsgId = 'voice_${DateTime.now().millisecondsSinceEpoch}_${(_messages.length + 1)}';
    unawaited(SecureStorageService.write('local_msg_txt_$clientMsgId', voiceText));

    final userPriv = await SecureStorageService.read('user_private_key') ?? '';
    String edPriv = '';
    if (userPriv.contains(':')) {
      final parts = userPriv.split(':');
      if (parts.length > 2) edPriv = parts[2];
    }
    final encrypted = await E2EECryptoService.encryptPayloadAsync(
      plaintext: voiceText,
      recipientPublicKey: widget.recipient['publicKey'] ?? '',
      senderPrivateKeyHex: userPriv,
      senderEd25519PrivateKeyHex: edPriv,
      conversationId: activeConvId,
    );

    final localMsg = {
      'id': clientMsgId,
      'conversationId': activeConvId,
      'senderId': widget.user['id'] ?? 'u1',
      'encryptedPayload': encrypted,
      'decryptedText': voiceText,
      'messageType': 'voice_note',
      'mediaPath': recordedFilePath ?? '',
      'duration': timeFormatted,
      'status': 'sending',
      'time': '${DateTime.now().hour > 12 ? DateTime.now().hour - 12 : DateTime.now().hour == 0 ? 12 : DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
      'isTyping': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (mounted) {
      setState(() {
        _messages.removeWhere((m) => m['isTyping'] == true);
        _messages.add(localMsg);
      });
      _scrollToBottom();
    }
    _saveRecentChatSnippet(voiceText);
    _persistMessagesCache();

    WebSocketClient().send({
      'type': 'chat_send',
      'messageId': clientMsgId,
      'conversationId': activeConvId,
      'senderId': widget.user['id'] ?? 'u1',
      'senderUsername': widget.user['username'],
      'senderProfileImage': widget.user['profileImage'],
      'recipientId': widget.recipient['id'] ?? 'u2',
      'recipientUsername': widget.recipient['username'],
      'recipientPrivateId': widget.recipient['privateId'],
      'encryptedPayload': encrypted,
      'messageType': 'voice_note',
      if (base64Audio.isNotEmpty) 'mediaPath': base64Audio,
      'duration': timeFormatted,
      'ttlSeconds': _ttlSeconds,
    });
  }

  void _showEmojiPickerModal() {
    final isDark = widget.isDarkMode;
    final cardBg = isDark ? const Color(0xFF14161C) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final emojis = [
      '😊', '😂', '❤️', '👍', '🔥', '😍', '🙏', '🎉',
      '💯', '👏', '🥳', '😎', '😭', '🤩', '🚀', '✨',
      '💬', '🔒', '🌟', '🍕', '💪', '🙌', '👌', '🥰',
      '🙄', '🤔', '😴', '💔', '😇', '🙈', '🌺', '☕',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Text('Select Emoji', style: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  return GestureDetector(
                    onTap: () {
                      _inputCtrl.text = _inputCtrl.text + emoji;
                      _inputCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _inputCtrl.text.length),
                      );
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? imageSource, {double size = 40, required String fallbackName}) {
    if (imageSource != null && imageSource.isNotEmpty) {
      if (imageSource.startsWith('data:image')) {
        try {
          final base64Data = imageSource.split(',').last;
          final bytes = base64Decode(base64Data);
          return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
        } catch (_) {}
      } else if (imageSource.length > 80 && !imageSource.contains('/') && !imageSource.startsWith('http')) {
        try {
          final bytes = base64Decode(imageSource);
          return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
        } catch (_) {}
      } else if (imageSource.startsWith('http')) {
        return Image.network(imageSource, width: size, height: size, fit: BoxFit.cover);
      } else if (File(imageSource).existsSync()) {
        return Image.file(File(imageSource), width: size, height: size, fit: BoxFit.cover);
      }
    }
    final clean = fallbackName.replaceAll('@', '').trim();
    final initial = clean.isNotEmpty ? clean[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(color: const Color(0xFF7B2FBE), fontWeight: FontWeight.bold, fontSize: size * 0.45),
      ),
    );
  }

  Future<void> _saveRecentChatSnippet(String lastMsgText) async {
    try {
      final recipientUname = widget.recipient['username']?.toString() ?? '';
      final recipientId = widget.recipient['id']?.toString() ?? '';
      if (recipientUname.isEmpty) return;

      final myUname = widget.user['username']?.toString() ?? '';
      final myId = widget.user['id']?.toString() ?? '';
      if (recipientUname == myUname || (recipientId.isNotEmpty && recipientId == myId)) {
        return;
      }

      final data = await SecureStorageService.read('recent_chats');
      List<Map<String, dynamic>> list = [];
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          list = List<Map<String, dynamic>>.from(decoded).where((item) {
            final uname = item['username']?.toString() ?? '';
            final id = item['id']?.toString() ?? '';
            return uname.isNotEmpty && uname != myUname && id != myId;
          }).toList();
        }
      }

      list.removeWhere((item) =>
        item['username'] == recipientUname ||
        (recipientId.isNotEmpty && item['id'] == recipientId)
      );

      list.insert(0, {
        'id': recipientId.isNotEmpty ? recipientId : recipientUname,
        'username': recipientUname,
        'privateId': widget.recipient['privateId'] ?? '',
        'publicKey': widget.recipient['publicKey'] ?? '',
        'profileImage': widget.recipient['profileImage'] ?? '',
        'unread': 0,
        'lastMessage': lastMsgText,
        'time': 'Just now',
      });

      await SecureStorageService.write('recent_chats', jsonEncode(list));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _checkGhostMode();
    _checkPeerOnlineStatus();
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
    } else {
      setState(() {
        _isGhostMode = false;
        _ttlSeconds = 0;
      });
    }
  }

  @override
  void dispose() {
    NativeSecurityService.disableFlagSecure();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  String _cleanDisplayText(String text, dynamic fallback) {
    if (text.isEmpty) {
      final fbStr = fallback?.toString() ?? '';
      return (fbStr.isNotEmpty && !fbStr.startsWith('[')) ? fbStr : 'Encrypted message';
    }
    String clean = text.trim();
    if (clean.startsWith('[Legacy Unauthenticated] ')) {
      clean = clean.substring('[Legacy Unauthenticated] '.length);
    }
    if (clean.startsWith('[Replay Error') || clean.startsWith('[Decryption Error')) {
      final fbStr = fallback?.toString() ?? '';
      if (fbStr.isNotEmpty && !fbStr.startsWith('[')) {
        return fbStr;
      }
      return 'Encrypted message';
    }
    return clean;
  }

  void _listenToWebSockets() {
    WebSocketClient().connect();
    _wsSubscription = WebSocketClient().stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'chat_receive') {
        final msg = event['message'] ?? event;
        if (msg['senderProfileImage'] != null && msg['senderProfileImage'].toString().isNotEmpty) {
          setState(() {
            widget.recipient['profileImage'] = msg['senderProfileImage'];
          });
        }
        final encrypted = msg['encryptedPayload'] ?? '';
        final msgId = msg['id'] ?? 'm_${DateTime.now().millisecondsSinceEpoch}';

        SecureStorageService.read('user_private_key').then((userPriv) async {
          String text = await SecureStorageService.read('local_msg_txt_$msgId') ?? '';
          if (text.isEmpty && encrypted.isNotEmpty) {
            text = await E2EECryptoService.decryptPayloadAsync(
              encryptedPayload: encrypted,
              recipientPrivateKeyHex: userPriv ?? '',
              senderPublicKey: widget.recipient['publicKey'] ?? '',
              conversationId: msg['conversationId'] ?? _conversationId ?? '',
              messageId: msgId,
            );
            if (text.isNotEmpty && !text.startsWith('[Decryption Error') && !text.startsWith('[Replay Error')) {
              await SecureStorageService.write('local_msg_txt_$msgId', text);
            }
          }

          final cleanText = _cleanDisplayText(text, msg['text'] ?? msg['decryptedText']);
          final existingIdx = _messages.indexWhere((m) => m['id'] == msgId);
          final existingMsg = existingIdx >= 0 ? _messages[existingIdx] : null;
          final rawMediaPath = (msg['mediaPath'] != null && msg['mediaPath'].toString().isNotEmpty)
              ? msg['mediaPath'].toString()
              : (existingMsg?['mediaPath']?.toString() ?? '');
          final savedMediaPath = (rawMediaPath.startsWith('data:image') || rawMediaPath.startsWith('data:audio'))
              ? await _saveIncomingMediaToFile(msgId, rawMediaPath)
              : rawMediaPath;

          final newMsg = {
            'id': msgId,
            'conversationId': msg['conversationId'] ?? _conversationId ?? '',
            'senderId': msg['senderId'] ?? widget.recipient['id'],
            'encryptedPayload': encrypted,
            'decryptedText': cleanText,
            'messageType': msg['messageType'] ?? existingMsg?['messageType'] ?? 'text',
            'mediaPath': savedMediaPath,
            'duration': msg['duration'] ?? existingMsg?['duration'],
            'isViewOnce': msg['isViewOnce'] == true ||
                msg['messageType'] == 'view_once_image' ||
                existingMsg?['isViewOnce'] == true,
            'status': msg['status'] ?? existingMsg?['status'] ?? 'delivered',
            'time': existingMsg?['time'] ?? 'Just now',
            'isTyping': false,
            'createdAt': msg['createdAt'] ?? existingMsg?['createdAt'] ?? DateTime.now().toIso8601String(),
          };

          // Confirm read receipt if user is actively on this chat screen
          if (msgId.isNotEmpty) {
            WebSocketClient().send({
              'type': 'chat_read',
              'messageId': msgId,
              'senderId': msg['senderId'],
              'recipientId': widget.user['id'],
            });
          }

          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m['isTyping'] == true);
              final existingIdx = _messages.indexWhere((m) => m['id'] == msgId);
              if (existingIdx >= 0) {
                _messages[existingIdx] = newMsg;
              } else {
                _messages.add(newMsg);
              }
            });
            _scrollToBottom();
            _persistMessagesCache();
          }

          // Sync Ghost Mode / TTL deletion on BOTH sender & receiver when sender sent with ttlSeconds > 0
          final msgTtl = int.tryParse(msg['ttlSeconds']?.toString() ?? '') ?? (_isGhostMode ? _ttlSeconds : 0);
          if (msgTtl > 0) {
            Timer(Duration(seconds: msgTtl), () {
              if (mounted) {
                setState(() {
                  _messages.removeWhere((m) => m['id'] == msgId);
                });
                _persistMessagesCache();
              }
            });
          }
        });
      } else if (type == 'chat_ack' || type == 'chat_delivered_ack' || type == 'chat_read_ack') {
        final ackId = event['messageId'];
        final newStatus = event['status'] ?? (type == 'chat_delivered_ack' ? 'delivered' : type == 'chat_read_ack' ? 'seen' : 'sent');
        if (ackId != null) {
          setState(() {
            for (final m in _messages) {
              if (m['id'] == ackId) {
                m['status'] = newStatus;
                break;
              }
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
      } else if (type == 'profile_update') {
        final rawSender = (event['senderUsername'] ?? '').toString().replaceAll('@', '').toLowerCase();
        final recipientUname = (widget.recipient['username'] ?? '').toString().replaceAll('@', '').toLowerCase();
        final senderId = (event['userId'] ?? event['senderId'] ?? '').toString();
        final recipientId = (widget.recipient['id'] ?? '').toString();

        if ((rawSender.isNotEmpty && rawSender == recipientUname) || (senderId.isNotEmpty && senderId == recipientId)) {
          if (event['profileImage'] != null && event['profileImage'].toString().isNotEmpty) {
            setState(() {
              widget.recipient['profileImage'] = event['profileImage'];
            });
          }
        }
      } else if (type == 'online_users_update') {
        final usersList = event['users'] as List?;
        if (usersList != null && mounted) {
          final recipientId = widget.recipient['id']?.toString();
          final recipientUname = widget.recipient['username']?.toString().replaceAll('@', '');
          final isOnlineNow = usersList.any((u) {
            final uMap = Map<String, dynamic>.from(u as Map);
            final uid = uMap['id']?.toString();
            final uname = uMap['username']?.toString().replaceAll('@', '');
            return (recipientId != null && uid == recipientId) || (recipientUname != null && uname == recipientUname);
          });
          setState(() {
            _isPeerOnline = isOnlineNow;
          });
        }
      } else if (type == 'user_online' || type == 'presence_online') {
        final uid = (event['userId'] ?? event['id'])?.toString();
        final uname = (event['username'])?.toString().replaceAll('@', '');
        final recipientId = widget.recipient['id']?.toString();
        final recipientUname = widget.recipient['username']?.toString().replaceAll('@', '');
        if ((recipientId != null && uid == recipientId) || (recipientUname != null && uname == recipientUname)) {
          if (mounted) setState(() => _isPeerOnline = true);
        }
      } else if (type == 'user_offline' || type == 'presence_offline') {
        final uid = (event['userId'] ?? event['id'])?.toString();
        final uname = (event['username'])?.toString().replaceAll('@', '');
        final recipientId = widget.recipient['id']?.toString();
        final recipientUname = widget.recipient['username']?.toString().replaceAll('@', '');
        if ((recipientId != null && uid == recipientId) || (recipientUname != null && uname == recipientUname)) {
          if (mounted) setState(() => _isPeerOnline = false);
        }
      } else if (type == 'call_log') {
        // Show call ended message as a chat bubble
        final callType = event['callType'] ?? 'audio';
        final durationSeconds = (event['durationSeconds'] ?? 0) as int;
        final logText = event['text'] ?? (callType == 'video' ? '📹 Video Call' : '📞 Voice Call');
        final isMine = event['senderId'] == widget.user['id'];
        setState(() {
          _messages.add({
            'id': 'call_${event['callId'] ?? DateTime.now().millisecondsSinceEpoch}',
            'senderId': event['senderId'],
            'decryptedText': logText,
            'time': '${DateTime.now().hour > 12 ? DateTime.now().hour - 12 : DateTime.now().hour == 0 ? 12 : DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
            'isCallLog': true,
            'callType': callType,
            'durationSeconds': durationSeconds,
            'isMine': isMine,
            'status': 'delivered',
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _initChat() async {
    try {
      final recipientId = widget.recipient['id']?.toString() ?? 'u2';
      final recipientUname = widget.recipient['username']?.toString() ?? '';

      // 1. Instant local cache load (0ms UI lag)
      String? convId = widget.recipient['conversationId']?.toString();
      if (convId == null || convId.isEmpty) {
        convId = await SecureStorageService.read('user_conv_$recipientId');
      }

      if (convId != null && convId.isNotEmpty) {
        _conversationId = convId;
        widget.recipient['conversationId'] = convId;
        unawaited(_loadMessages(convId));
      } else {
        // Fallback: load cached messages using recipient ID key if convId not yet established
        unawaited(_loadCachedMessagesByRecipient(recipientId));
      }

      // 2. Network sync in background (Public key lookup, server conversation & latest messages)
      unawaited(_syncChatNetwork(recipientId, recipientUname));
    } catch (_) {}
  }

  Future<void> _loadCachedMessagesByRecipient(String recipientId) async {
    try {
      final cachedJson = await SecureStorageService.read('conv_msgs_user_$recipientId');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final cachedList = List<Map<String, dynamic>>.from(jsonDecode(cachedJson));
        if (mounted && _messages.isEmpty && cachedList.isNotEmpty) {
          setState(() {
            _messages.addAll(cachedList);
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _syncChatNetwork(String recipientId, String recipientUname) async {
    try {
      // Fetch public key if missing
      final currentPubKey = widget.recipient['publicKey']?.toString() ?? '';
      if (currentPubKey.isEmpty || !currentPubKey.startsWith('PUB_X25519:')) {
        try {
          final query = recipientUname.isNotEmpty ? recipientUname : recipientId;
          final lookupRes = await ApiClient.get('/users/lookup?query=$query');
          if (lookupRes['publicKey'] != null && mounted) {
            setState(() {
              widget.recipient['publicKey'] = lookupRes['publicKey'];
            });
          }
        } catch (_) {}
      }

      // Fetch or confirm conversation ID from server
      String? serverConvId = _conversationId;
      if (serverConvId == null || serverConvId.isEmpty) {
        final res = await ApiClient.post('/chat/conversation', {'recipientId': recipientId});
        serverConvId = res['conversationId']?.toString();
      }

      if (serverConvId != null && serverConvId.isNotEmpty) {
        _conversationId = serverConvId;
        widget.recipient['conversationId'] = serverConvId;
        unawaited(SecureStorageService.write('user_conv_$recipientId', serverConvId));
        await _loadMessages(serverConvId);
      }
    } catch (_) {}
  }

  Future<void> _loadMessages(String convId) async {
    final recipientId = widget.recipient['id']?.toString();

    // 1. Instant local cache load for instant UI response
    try {
      String? cachedJson = await SecureStorageService.read('conv_msgs_$convId');
      if (cachedJson == null || cachedJson.isEmpty) {
        if (recipientId != null) {
          cachedJson = await SecureStorageService.read('conv_msgs_user_$recipientId');
        }
      }
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final cachedList = List<Map<String, dynamic>>.from(jsonDecode(cachedJson));
        if (mounted && _messages.isEmpty && cachedList.isNotEmpty) {
          setState(() {
            _messages.addAll(cachedList);
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}

    // 2. Fetch latest messages from server & decrypt concurrently
    try {
      final res = await ApiClient.get('/chat/messages/$convId');
      final rawMsgs = res['messages'] as List<dynamic>;
      if (rawMsgs.isNotEmpty) {
        final currentUserId = widget.user['id']?.toString() ?? '';
        final userPriv = await SecureStorageService.read('user_private_key') ?? '';
        final recipientPubKey = widget.recipient['publicKey']?.toString() ?? '';

        final decryptedList = await Future.wait(rawMsgs.map((msg) async {
          final msgId = msg['id']?.toString() ?? '';
          final senderId = msg['senderId']?.toString() ?? '';

          // Trigger read receipt for unread incoming messages
          if (senderId != currentUserId && msg['status'] != 'seen' && msgId.isNotEmpty) {
            WebSocketClient().send({
              'type': 'chat_read',
              'messageId': msgId,
              'senderId': senderId,
              'recipientId': currentUserId,
            });
          }

          String text = await SecureStorageService.read('local_msg_txt_$msgId') ?? '';
          if (text.isEmpty) {
            if (senderId == currentUserId) {
              text = msg['text'] ?? msg['decryptedText'] ?? '';
            } else {
              text = await E2EECryptoService.decryptPayloadAsync(
                encryptedPayload: msg['encryptedPayload'] ?? '',
                recipientPrivateKeyHex: userPriv,
                senderPublicKey: recipientPubKey,
                conversationId: convId,
                messageId: msgId,
              );
              if (text.isNotEmpty && !text.startsWith('[Decryption Error') && !text.startsWith('[Replay Error') && msgId.isNotEmpty) {
                unawaited(SecureStorageService.write('local_msg_txt_$msgId', text));
              }
            }
          }

          String timeStr = 'Just now';
          if (msg['createdAt'] != null) {
            try {
              final dt = DateTime.parse(msg['createdAt']).toLocal();
              timeStr = '${dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
            } catch (_) {}
          }

          final cleanText = _cleanDisplayText(text, msg['text'] ?? msg['decryptedText']);
          return <String, dynamic>{
            ...msg,
            'decryptedText': cleanText,
            'time': timeStr,
            'isTyping': false
          };
        }));

        if (mounted) {
          setState(() {
            for (final newM in decryptedList) {
              final idx = _messages.indexWhere((m) => m['id'] == newM['id']);
              if (idx >= 0) {
                _messages[idx] = {..._messages[idx], ...newM};
              } else {
                _messages.add(newM);
              }
            }
            // Sort chronologically
            _messages.sort((a, b) {
              final ca = a['createdAt']?.toString() ?? '';
              final cb = b['createdAt']?.toString() ?? '';
              return ca.compareTo(cb);
            });
          });
          _scrollToBottom();
          // Update persistent conversation message cache asynchronously (without multi-MB base64 blobs)
          _persistMessagesCache();
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    _inputCtrl.clear();

    final clientMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${(_messages.length + 1)}';
    final localMsg = {
      'id': clientMsgId,
      'conversationId': _conversationId ?? 'c1',
      'senderId': widget.user['id'] ?? 'u1',
      'encryptedPayload': '',
      'decryptedText': text,
      'messageType': 'text',
      'status': 'sending',
      'time': '${DateTime.now().hour > 12 ? DateTime.now().hour - 12 : DateTime.now().hour == 0 ? 12 : DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
      'isTyping': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.removeWhere((m) => m['isTyping'] == true);
      _messages.add(localMsg);
    });
    _scrollToBottom();
    _saveRecentChatSnippet(text);
    _persistMessagesCache();

    // Ensure conversation ID is created (only if missing)
    if (_conversationId == null || _conversationId!.isEmpty) {
      try {
        final res = await ApiClient.post('/chat/conversation', {'recipientId': widget.recipient['id'] ?? 'u2'});
        _conversationId = res['conversationId'];
      } catch (_) {}
    }

    unawaited(SecureStorageService.write('local_msg_txt_$clientMsgId', text));

    final userPriv = await SecureStorageService.read('user_private_key') ?? '';
    String edPriv = '';
    if (userPriv.contains(':')) {
      final parts = userPriv.split(':');
      if (parts.length > 2) edPriv = parts[2];
    }
    final encrypted = await E2EECryptoService.encryptPayloadAsync(
      plaintext: text,
      recipientPublicKey: widget.recipient['publicKey'] ?? '',
      senderPrivateKeyHex: userPriv,
      senderEd25519PrivateKeyHex: edPriv,
      conversationId: _conversationId,
    );
    localMsg['encryptedPayload'] = encrypted;
    _persistMessagesCache();

    if (_isGhostMode && _ttlSeconds > 0) {
      final msgId = localMsg['id'];
      Timer(Duration(seconds: _ttlSeconds), () {
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == msgId);
          });
          _persistMessagesCache();
        }
      });
    }

    if (_conversationId != null) {
      WebSocketClient().send({
        'type': 'chat_send',
        'messageId': clientMsgId,
        'conversationId': _conversationId,
        'senderId': widget.user['id'] ?? 'u1',
        'senderUsername': widget.user['username'],
        'senderProfileImage': widget.user['profileImage'],
        'recipientId': widget.recipient['id'] ?? 'u2',
        'recipientUsername': widget.recipient['username'],
        'recipientPrivateId': widget.recipient['privateId'],
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

  Widget _buildStatusIcon(String? status) {
    if (status == 'seen') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF38BDF8));
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
    } else if (status == 'sent') {
      return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
    } else {
      return const Icon(Icons.access_time_rounded, size: 12, color: Colors.white60);
    }
  }

  Widget _buildChatBubbleContent(Map<String, dynamic> item, bool isMe, Color peerBubbleBg, Color peerTxtColor) {
    final messageType = item['messageType'] ?? 'text';
    final mediaPath = item['mediaPath']?.toString() ?? '';
    final isViewOnce = messageType == 'view_once_image' || item['isViewOnce'] == true;
    final status = item['status']?.toString();

    if (messageType == 'voice_note' || item['decryptedText']?.toString().startsWith('🎵') == true) {
      final msgId = item['id']?.toString() ?? '';
      final isPlaying = _playingMsgId == msgId && msgId.isNotEmpty;
      final durationStr = item['duration'] ?? '0:05';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF7B2FBE) : peerBubbleBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                if (isPlaying) {
                  await _audioPlayer.stop();
                  if (mounted) setState(() => _playingMsgId = null);
                  return;
                }
                if (mediaPath.isNotEmpty) {
                  try {
                    await _audioPlayer.stop();
                    _audioPlayer.onPlayerComplete.first.then((_) {
                      if (mounted) setState(() => _playingMsgId = null);
                    });
                    if (mediaPath.startsWith('data:audio')) {
                      final bytes = base64Decode(mediaPath.split(',').last);
                      await _audioPlayer.play(BytesSource(bytes));
                    } else if (File(mediaPath).existsSync()) {
                      await _audioPlayer.play(DeviceFileSource(mediaPath));
                    }
                    if (mounted) setState(() => _playingMsgId = msgId);
                  } catch (e) {
                    debugPrint('Voice playback error: $e');
                  }
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isMe ? Colors.white24 : const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : const Color(0xFF7B2FBE),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(14, (i) {
                    final h = [10.0, 16.0, 8.0, 22.0, 14.0, 18.0, 12.0, 24.0, 16.0, 10.0, 18.0, 12.0, 20.0, 8.0][i % 14];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 3,
                      height: h,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: isPlaying ? 0.9 : 0.6) : const Color(0xFF7B2FBE).withValues(alpha: isPlaying ? 0.9 : 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  durationStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              _buildStatusIcon(status),
            ],
          ],
        ),
      );
    }

    if (messageType == 'image' || messageType == 'view_once_image' || mediaPath.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (mediaPath.isNotEmpty) {
            widget.onOpenImageViewer(mediaPath, isViewOnce);
          }
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF7B2FBE) : peerBubbleBg,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mediaPath.isNotEmpty)
                Stack(
                  children: [
                    _renderImageWidget(mediaPath, 180),
                    if (isViewOnce)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 6),
                                Text('View-Once Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.black12,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isViewOnce ? Icons.visibility_off_rounded : Icons.image_rounded, color: isMe ? Colors.white70 : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          isViewOnce ? 'View-Once Photo' : 'Photo Attachment',
                          style: TextStyle(color: isMe ? Colors.white : peerTxtColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              if (item['decryptedText'] != null &&
                  item['decryptedText'].toString().isNotEmpty &&
                  !item['decryptedText'].toString().startsWith('📷'))
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          item['decryptedText'],
                          style: TextStyle(color: isMe ? Colors.white : peerTxtColor, fontSize: 13),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(status),
                      ]
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF7B2FBE) : peerBubbleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
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
          if (isMe) ...[
            const SizedBox(width: 6),
            _buildStatusIcon(status),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAttachmentImage(ImageSource source, {bool isViewOnce = false}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
      if (picked != null && mounted) {
        _showSendImagePreviewDialog(picked.path, isViewOnce: isViewOnce, isVideo: false);
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  void _showSendImagePreviewDialog(String imagePath, {bool isViewOnce = false, bool isVideo = false}) {
    final captionCtrl = TextEditingController();

    bool currentViewOnce = isViewOnce;
    int currentTimerSeconds = 0; // 0 = off, 30 = 30s timer, 300 = 5m

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Column(
                  children: [
                    // TOP WHATSAPP TOOLBAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const Spacer(),
                          if (currentViewOnce)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.looks_one_rounded, color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 4),
                                  Text('View Once', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else if (currentTimerSeconds > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B2FBE).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF7B2FBE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, color: Color(0xFF7B2FBE), size: 14),
                                  const SizedBox(width: 4),
                                  Text('${currentTimerSeconds}s Timer', style: const TextStyle(color: Color(0xFF7B2FBE), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.crop_rotate_rounded, color: Colors.white, size: 22),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.title_rounded, color: Colors.white, size: 22),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    // CENTER MEDIA VIEW
                    Expanded(
                      child: Center(
                        child: File(imagePath).existsSync() && !isVideo
                            ? Image.file(
                                File(imagePath),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              )
                            : Container(
                                color: const Color(0xFF111827),
                                child: Center(
                                  child: Icon(
                                    isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                                    size: 72,
                                    color: const Color(0xFF7B2FBE),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // VIEW ONCE / TIMER NOTICE BADGE
                    if (currentViewOnce)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('Photo set to view once', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else if (currentTimerSeconds > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Color(0xFF7B2FBE), size: 14),
                            const SizedBox(width: 6),
                            Text('Auto-deletes ${currentTimerSeconds}s after viewing', style: const TextStyle(color: Color(0xFF7B2FBE), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                    // BOTTOM WHATSAPP CAPTION & SEND BAR
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2C34),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: captionCtrl,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: const InputDecoration(
                                        hintText: 'Add a caption...',
                                        hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),

                                  // WhatsApp Style "1" View Once Toggle Button
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        currentViewOnce = !currentViewOnce;
                                        if (currentViewOnce) currentTimerSeconds = 0;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: currentViewOnce ? const Color(0xFF10B981) : Colors.white24,
                                        child: Icon(
                                          Icons.looks_one_rounded,
                                          size: 16,
                                          color: currentViewOnce ? Colors.black : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // WhatsApp Style Timer Toggle Button
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (currentTimerSeconds == 0) {
                                          currentTimerSeconds = 30;
                                          currentViewOnce = false;
                                        } else if (currentTimerSeconds == 30) {
                                          currentTimerSeconds = 300;
                                        } else {
                                          currentTimerSeconds = 0;
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: currentTimerSeconds > 0 ? const Color(0xFF7B2FBE) : Colors.white24,
                                        child: Icon(
                                          currentTimerSeconds == 30 ? Icons.timer_3_rounded : Icons.timer_outlined,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // WhatsApp Circular Send Floating Action Button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _sendImageMessage(
                                imagePath,
                                isViewOnce: currentViewOnce,
                                isVideo: isVideo,
                                caption: captionCtrl.text.trim(),
                                ttlSecondsOverride: currentTimerSeconds > 0 ? currentTimerSeconds : null,
                              );
                            },
                            child: const CircleAvatar(
                              radius: 25,
                              backgroundColor: Color(0xFF10B981), // Iconic WhatsApp Green Send Button
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageStatusIcon(String status) {
    if (status == 'seen' || status == 'read') {
      return const Icon(
        Icons.done_all_rounded,
        color: Color(0xFF0284C7), // WhatsApp-style Cyan/Blue double tick for read
        size: 16,
      );
    } else if (status == 'delivered') {
      return const Icon(
        Icons.done_all_rounded,
        color: Color(0xFF94A3B8), // Grey double tick for delivered
        size: 16,
      );
    } else if (status == 'sending') {
      return const Icon(
        Icons.access_time_rounded,
        color: Color(0xFF94A3B8), // Clock for sending
        size: 14,
      );
    } else {
      return const Icon(
        Icons.done_rounded,
        color: Color(0xFF94A3B8), // Single grey tick for sent
        size: 16,
      );
    }
  }

  Widget _renderImageWidget(String mediaPath, double height) {
    if (mediaPath.isEmpty) return const SizedBox.shrink();
    if (File(mediaPath).existsSync()) {
      return Image.file(
        File(mediaPath),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    if (mediaPath.startsWith('data:image')) {
      try {
        final commaIdx = mediaPath.indexOf(',');
        final base64Str = commaIdx != -1 ? mediaPath.substring(commaIdx + 1) : mediaPath;
        final bytes = base64Decode(base64Str.trim());
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    } else if (mediaPath.length > 100 && !mediaPath.contains('/')) {
      try {
        final bytes = base64Decode(mediaPath.trim());
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    } else if (mediaPath.startsWith('http')) {
      return Image.network(
        mediaPath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.black12,
      child: const Center(child: Icon(Icons.image_rounded, color: Colors.grey)),
    );
  }

  void _sendImageMessage(String imagePath, {bool isViewOnce = false, bool isVideo = false, String caption = '', int? ttlSecondsOverride}) async {
    final typeStr = isVideo ? 'video' : (isViewOnce ? 'view_once_image' : 'image');
    final text = caption.isNotEmpty ? caption : (isVideo ? '🎥 Video' : (isViewOnce ? '📷 View-once photo' : '📷 Photo'));
    final effectiveTtl = ttlSecondsOverride ?? _ttlSeconds;

    // 1. Ensure conversation ID is created
    if (_conversationId == null || _conversationId!.isEmpty) {
      try {
        final res = await ApiClient.post('/chat/conversation', {'recipientId': widget.recipient['id'] ?? 'u2'});
        _conversationId = res['conversationId'];
      } catch (_) {}
    }

    // 2. Encode media file as base64 string for cross-device transmission
    String base64Media = imagePath;
    try {
      if (File(imagePath).existsSync()) {
        final bytes = await File(imagePath).readAsBytes();
        final mimeType = isVideo ? 'data:video/mp4;base64,' : 'data:image/jpeg;base64,';
        base64Media = '$mimeType${base64Encode(bytes)}';
      }
    } catch (_) {}

    final userPriv = await SecureStorageService.read('user_private_key') ?? '';
    String edPriv = '';
    if (userPriv.contains(':')) {
      final parts = userPriv.split(':');
      if (parts.length > 2) edPriv = parts[2];
    }
    final encrypted = await E2EECryptoService.encryptPayloadAsync(
      plaintext: text,
      recipientPublicKey: widget.recipient['publicKey'] ?? '',
      senderPrivateKeyHex: userPriv,
      senderEd25519PrivateKeyHex: edPriv,
      conversationId: _conversationId,
    );
    
    final clientMsgId = 'media_${DateTime.now().millisecondsSinceEpoch}_${(_messages.length + 1)}';
    final localMsg = {
      'id': clientMsgId,
      'conversationId': _conversationId ?? 'c1',
      'senderId': widget.user['id'] ?? 'u1',
      'encryptedPayload': encrypted,
      'decryptedText': text,
      'messageType': typeStr,
      'mediaPath': imagePath,
      'isViewOnce': isViewOnce,
      'ttlSeconds': effectiveTtl,
      'status': 'sending',
      'time': '${DateTime.now().hour > 12 ? DateTime.now().hour - 12 : DateTime.now().hour == 0 ? 12 : DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
      'isTyping': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.removeWhere((m) => m['isTyping'] == true);
      _messages.add(localMsg);
    });
    _scrollToBottom();
    _saveRecentChatSnippet(text);
    _persistMessagesCache();

    if (_conversationId != null) {
      WebSocketClient().send({
        'type': 'chat_send',
        'messageId': clientMsgId,
        'conversationId': _conversationId,
        'senderId': widget.user['id'] ?? 'u1',
        'senderUsername': widget.user['username'],
        'senderProfileImage': widget.user['profileImage'],
        'recipientId': widget.recipient['id'] ?? 'u2',
        'recipientUsername': widget.recipient['username'],
        'recipientPrivateId': widget.recipient['privateId'],
        'encryptedPayload': encrypted,
        'messageType': typeStr,
        'mediaPath': base64Media,
        'isViewOnce': isViewOnce,
        'ttlSeconds': effectiveTtl,
      });
    }
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
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Share Media', style: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF7B2FBE),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
                title: Text('Camera', style: TextStyle(color: txtColor, fontWeight: FontWeight.w600)),
                subtitle: const Text('Take photo or record video directly', style: TextStyle(fontSize: 11, color: Colors.grey)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WhatsAppCameraScreen()),
                    );
                    if (res != null && res is Map && res['path'] != null && mounted) {
                      _showSendImagePreviewDialog(
                        res['path'],
                        isViewOnce: false,
                        isVideo: res['isVideo'] == true,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                ),
                title: Text('Gallery', style: TextStyle(color: txtColor, fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose photo from gallery', style: TextStyle(fontSize: 11, color: Colors.grey)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) _pickAttachmentImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_rounded, color: Color(0xFF7B2FBE), size: 20),
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
              {'label': '1 Hour', 'sec': 3600},
              {'label': '24 Hours', 'sec': 86400},
            ].map((opt) {
              final sec = opt['sec'] as int;
              final isSel = _ttlSeconds == sec;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(opt['label'] as String, style: TextStyle(color: isSel ? const Color(0xFF7B2FBE) : titleTxt, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7B2FBE)) : null,
                onTap: () {
                  setState(() => _ttlSeconds = sec);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final raw = await SecureStorageService.read('blocked_users');
                final List<String> blocked = raw != null && raw.isNotEmpty
                    ? List<String>.from(jsonDecode(raw))
                    : <String>[];
                final rid = (widget.recipient['id'] ?? '').toString().trim().toLowerCase();
                final runame = (widget.recipient['username'] ?? '').toString().trim().toLowerCase();
                if (rid.isNotEmpty && !blocked.contains(rid)) blocked.add(rid);
                if (runame.isNotEmpty && !blocked.contains(runame)) blocked.add(runame);
                await SecureStorageService.write('blocked_users', jsonEncode(blocked));
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$rawName has been blocked'), duration: const Duration(seconds: 2), backgroundColor: const Color(0xFFF43F5E)),
                );
                widget.onBack();
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportUserDialog() {
    final isDark = widget.isDarkMode;
    final rawName = widget.recipient['username'] ?? 'User';
    String selectedReason = 'Spam or Scam';
    final reasons = ['Spam or Scam', 'Harassment or Bullying', 'Inappropriate Content', 'Fake Account'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Report $rawName', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a reason for reporting this contact. Our safety team reviews abuse reports promptly.',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...reasons.map((r) {
                final isSelected = selectedReason == r;
                return InkWell(
                  onTap: () => setStateDialog(() => selectedReason = r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? const Color(0xFF7B2FBE) : (isDark ? Colors.white54 : Colors.black45),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(r, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
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
                ApiClient.post('/users/report', {
                  'reportedUserId': widget.recipient['id'] ?? rawName,
                  'reason': selectedReason,
                }).catchError((_) => <String, dynamic>{});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$rawName reported ($selectedReason). Thank you for keeping OurSpace safe.'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipientProfileModal() {
    final rawName = widget.recipient['username'] ?? 'User';
    final displayName = rawName;
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
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
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
                        colors: [Color(0xFF7B2FBE), Color(0xFFBB3FDE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(color: const Color(0xFF7B2FBE), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: _buildAvatarImage(
                  widget.recipient['profileImage'] ?? profileImgPath,
                  size: 104,
                  fallbackName: displayName,
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
              style: const TextStyle(color: Color(0xFF7B2FBE), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Online Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPeerOnline
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 3.5,
                        backgroundColor: _isPeerOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPeerOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _isPeerOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
                  Text('Private ID: $privateId', style: const TextStyle(color: Color(0xFF7B2FBE), fontSize: 12, fontWeight: FontWeight.w600)),
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
          color: const Color(0xFF7B2FBE).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7B2FBE), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Color(0xFF7B2FBE), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawName = widget.recipient['username'] ?? 'User';
    final displayName = rawName;
    final isDark = widget.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final headerTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = scaffoldBg;
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
                              backgroundColor: const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: _buildAvatarImage(
                                  widget.recipient['profileImage'],
                                  size: 38,
                                  fallbackName: displayName,
                                ),
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
                                        decoration: BoxDecoration(
                                          color: _isPeerOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _isPeerOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isPeerOnline
                                              ? const Color(0xFF10B981)
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                      icon: const Icon(Icons.phone_outlined, color: Color(0xFF7B2FBE), size: 24),
                      onPressed: () => widget.onStartCall('audio', widget.recipient),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam_outlined, color: Color(0xFF7B2FBE), size: 24),
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
                          case 'report':
                            _showReportUserDialog();
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
                          value: 'report',
                          child: const Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 12),
                              Text('Report Contact', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14, fontWeight: FontWeight.w600)),
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
                  color: cardBg,
                  child: Column(
                    children: [
                      if (_isGhostMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FBE).withValues(alpha: 0.14),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            border: Border(bottom: BorderSide(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3))),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_off_rounded, color: Color(0xFF7B2FBE), size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '👻 GHOST MODE ACTIVE: 30s Auto-Disappear & View-Once',
                                  style: TextStyle(color: Color(0xFF7B2FBE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: peerTxtColor.withValues(alpha: 0.7), shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: peerTxtColor.withValues(alpha: 0.4), shape: BoxShape.circle)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Call log bubble (centered, like WhatsApp)
                      final isCallLog = item['isCallLog'] == true;
                      if (isCallLog) {
                        final cType = item['callType'] ?? 'audio';
                        final cIcon = cType == 'video' ? Icons.videocam_rounded : Icons.call_rounded;
                        final cColor = cType == 'video' ? const Color(0xFF7B2FBE) : const Color(0xFF0052CC);
                        final cText = item['decryptedText'] ?? '📞 Voice Call';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cIcon, size: 16, color: cColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    cText,
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                  child: _buildChatBubbleContent(item, isMe, peerBubbleBg, peerTxtColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // STATUS ROW BELOW BUBBLE
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe) const SizedBox(width: 46),
                                if (isMe) ...[
                                  _buildMessageStatusIcon(item['status']?.toString() ?? 'sent'),
                                  const SizedBox(width: 4),
                                ],
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
                child: _isRecordingVoice
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 26),
                            onPressed: _cancelVoiceRecording,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mic_rounded, color: Color(0xFFF43F5E), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recording Voice Note... ${(_recordSeconds ~/ 60)}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendVoiceNote,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Purple Circle '+' Button
                          GestureDetector(
                            onTap: _showAttachmentOptions,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7B2FBE),
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
                                      onChanged: (_) {
                                        if (mounted) setState(() {});
                                      },
                                      onSubmitted: (_) => _handleSend(),
                                      style: TextStyle(color: inputTxt, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Message...',
                                        hintStyle: TextStyle(color: inputHint, fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.sentiment_satisfied_alt_rounded, color: inputHint, size: 22),
                                    onPressed: _showEmojiPickerModal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Send Button when text is present, or Mic Button when empty
                          GestureDetector(
                            onTap: () {
                              if (_inputCtrl.text.trim().isNotEmpty) {
                                _handleSend();
                              } else {
                                _startVoiceRecording();
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7B2FBE),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _inputCtrl.text.trim().isNotEmpty ? Icons.send_rounded : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
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
