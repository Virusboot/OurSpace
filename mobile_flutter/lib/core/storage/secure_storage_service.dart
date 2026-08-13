import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static final Map<String, String> _inMemoryFallback = {};

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _inMemoryFallback[key] = value;
    }
  }

  static Future<String?> read(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    return _inMemoryFallback[key];
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    _inMemoryFallback.remove(key);
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    _inMemoryFallback.clear();
  }
}
