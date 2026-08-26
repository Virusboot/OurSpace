import 'dart:async';
import 'dart:convert';
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
  bool _isExplicitlyDisconnected = false;

  Stream<Map<String, dynamic>> get stream => _messageController.stream;
  bool get isConnected => _channel != null;

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

      send({
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
            _messageController.add(parsed);
          } catch (_) {}
        },
        onError: (err) {
          _isConnecting = false;
          _channel = null;
          _reconnect();
        },
        onDone: () {
          _isConnecting = false;
          _channel = null;
          _reconnect();
        },
      );

      _isConnecting = false;
      _flushQueue();
    } catch (_) {
      _isConnecting = false;
      _channel = null;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isExplicitlyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      connect();
    });
  }

  void send(Map<String, dynamic> payload) {
    if (_channel != null) {
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
      } catch (_) {}
    }
  }

  void disconnect() {
    _isExplicitlyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
  }
}
