import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage_service.dart';

class WebSocketClient {
  static final WebSocketClient _instance = WebSocketClient._internal();
  factory WebSocketClient() => _instance;
  WebSocketClient._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _messageController.stream;

  Future<void> connect() async {
    final token = await SecureStorageService.read('auth_token');
    if (token == null) return;

    final wsUrl = (!kIsWeb && Platform.isAndroid) ? 'ws://10.0.2.2:4000/ws' : 'ws://localhost:4000/ws';
    try {
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
          _reconnect();
        },
        onDone: () {
          _reconnect();
        },
      );
    } catch (_) {
      _reconnect();
    }
  }

  void _reconnect() {
    Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void send(Map<String, dynamic> payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
