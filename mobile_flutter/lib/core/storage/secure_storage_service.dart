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
  static final Map<String, String> _memoryCache = {};

  static Future<void> write(String key, String value) async {
    _memoryCache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _inMemoryFallback[key] = value;
    }
  }

  static Future<String?> read(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final val = await _storage.read(key: key);
      if (val != null) {
        _memoryCache[key] = val;
        return val;
      }
    } catch (_) {}
    return _inMemoryFallback[key];
  }

  static Future<void> delete(String key) async {
    _memoryCache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    _inMemoryFallback.remove(key);
  }

  static Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
    _inMemoryFallback.clear();
  }
}
