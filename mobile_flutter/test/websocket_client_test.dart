import 'package:flutter_test/flutter_test.dart';
import 'package:ourspace_flutter/core/networking/websocket_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketClient Unit Tests', () {
    test('1. Singleton instance verification', () {
      final instance1 = WebSocketClient();
      final instance2 = WebSocketClient();
      expect(identical(instance1, instance2), true);
    });

    test('2. Initial connection state should be disconnected', () {
      final client = WebSocketClient();
      expect(client.isConnected, false);
      expect(client.isAuthenticated, false);
    });
  });
}
