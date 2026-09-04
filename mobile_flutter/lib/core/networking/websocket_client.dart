import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage_service.dart';

class WebSocketClient {
  static final WebSocketClient _instance = WebSocketClient._internal();
  factory WebSocketClient() => _instance;
  WebSocketClient._internal();

  static String? customWsUrl;

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final List<Map<String, dynamic>> _pendingQueue = [];
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isAuthenticated = false;
  bool _isExplicitlyDisconnected = false;
  int _reconnectAttempts = 0;

  Stream<Map<String, dynamic>> get stream => _messageController.stream;
  bool get isConnected => _channel != null;
  bool get isAuthenticated => _isAuthenticated;

  void ensureConnected() {
    if (_channel == null && !_isConnecting) {
      connect();
    }
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (_channel != null && !_isExplicitlyDisconnected) return;

    _isExplicitlyDisconnected = false;
    _isConnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    String wsUrl;
    if (customWsUrl != null && customWsUrl!.isNotEmpty) {
      wsUrl = customWsUrl!;
    } else {
      wsUrl = 'wss://ourspace-d81w.onrender.com/ws';
    }

    try {
      await _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      final token = await SecureStorageService.read('auth_token');
      final userInfoStr = await SecureStorageService.read('user_info');
      Map<String, dynamic>? uObj;
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        try {
          uObj = jsonDecode(userInfoStr);
        } catch (_) {}
      }

      // Send authentication payload immediately on connection open
      sendDirect({
        'type': 'auth',
        'token': token ?? '',
        'userId': uObj?['id'],
        'username': uObj?['username'],
        'privateId': uObj?['privateId'],
      });

      _channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString()) as Map<String, dynamic>;
            final type = parsed['type'];

            if (type == 'auth_ack') {
              if (parsed['success'] == true) {
                _isAuthenticated = true;
                _reconnectAttempts = 0;
                _flushQueue();
              }
            } else if (type == 'chat_receive') {
              // Automatically confirm delivery receipt back to server
              final msg = parsed['message'] ?? parsed;
              final msgId = msg['id'];
              final senderId = msg['senderId'];
              if (msgId != null) {
                sendDirect({
                  'type': 'chat_delivered',
                  'messageId': msgId,
                  'senderId': senderId
                });
              }
            }

            _messageController.add(parsed);
          } catch (e) {
            debugPrint('[WebSocketClient] Error parsing message: $e');
          }
        },
        onError: (err) {
          _isConnecting = false;
          _isAuthenticated = false;
          _channel = null;
          _reconnect();
        },
        onDone: () {
          _isConnecting = false;
          _isAuthenticated = false;
          _channel = null;
          _reconnect();
        },
      );

      _isConnecting = false;
    } catch (err) {
      _isConnecting = false;
      _isAuthenticated = false;
      _channel = null;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isExplicitlyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (1 << (_reconnectAttempts - 1)).clamp(1, 30);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  void sendDirect(Map<String, dynamic> payload) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
      } catch (_) {}
    }
  }

  void send(Map<String, dynamic> payload) {
    if (_channel != null && _isAuthenticated) {
      try {
        _channel!.sink.add(jsonEncode(payload));
      } catch (e) {
        _pendingQueue.add(payload);
        connect();
      }
    } else {
      _pendingQueue.add(payload);
      connect();
    }
  }

  void _flushQueue() {
    if (_channel == null || _pendingQueue.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final payload in copy) {
      try {
        _channel!.sink.add(jsonEncode(payload));
      } catch (_) {
        _pendingQueue.add(payload);
      }
    }
  }

  void disconnect() {
    _isExplicitlyDisconnected = true;
    _isAuthenticated = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
    _reconnectAttempts = 0;
  }
}
