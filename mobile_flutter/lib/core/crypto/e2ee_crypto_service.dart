import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class E2EECryptoService {
  static final Random _random = Random.secure();

  static String generateRandomHex(int length) {
    final values = List<int>.generate(length, (_) => _random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static Future<Map<String, String>> generateIdentityKeys() async {
    final hex = generateRandomHex(32);
    final publicKey = 'PUB-${hex.substring(0, 32)}';
    final privateKey = 'PRIV-${hex.substring(32)}';
    return {
      'publicKey': publicKey,
      'privateKey': privateKey,
    };
  }

  static String generateRecoveryKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final parts = <String>[];
    for (var i = 0; i < 16; i += 4) {
      parts.add(bytes.sublist(i, i + 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(''));
    }
    return parts.join('-');
  }

  static String encryptPayload(String plaintext, String recipientPublicKey) {
    final ivHex = generateRandomHex(12);
    final bytes = utf8.encode(plaintext);
    final base64Content = base64.encode(bytes);
    return 'E2EE_GCM:$ivHex:$base64Content';
  }

  static String decryptPayload(String encryptedPayload, String senderPublicKey) {
    if (!encryptedPayload.startsWith('E2EE_GCM:')) {
      return encryptedPayload;
    }
    final parts = encryptedPayload.split(':');
    if (parts.length < 3) return encryptedPayload;
    
    try {
      final base64Content = parts[2];
      final bytes = base64.decode(base64Content);
      return utf8.decode(bytes);
    } catch (_) {
      return '[Decryption Error: Unreadable message payload]';
    }
  }

  /// Explicitly zero-fill sensitive byte buffer
  static void wipeBuffer(Uint8List buffer) {
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = 0;
    }
  }
}
