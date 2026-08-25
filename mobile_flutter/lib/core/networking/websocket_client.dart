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
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isExplicitlyDisconnected = false;

  Stream<Map<String, dynamic>> get stream => _messageController.stream;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isExplicitlyDisconnected = false;
    _isConnecting = true;

    final token = await SecureStorageService.read('auth_token');
    if (token == null) {
      _isConnecting = false;
      return;
    }

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
      
      // Handshake authentication
      send({'type': 'auth', 'token': token});

      _channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString()) as Map<String, dynamic>;
            _messageController.add(parsed);
          } catch (_) {}
        },
        onError: (err) {
          _isConnecting = false;
          _reconnect();
        },
        onDone: () {
          _isConnecting = false;
          _reconnect();
        },
      );
      _isConnecting = false;
    } catch (_) {
      _isConnecting = false;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isExplicitlyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void send(Map<String, dynamic> payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(payload));
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
