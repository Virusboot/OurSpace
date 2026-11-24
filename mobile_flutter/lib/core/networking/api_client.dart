import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient {
  static String? customBaseUrl;
  static String? customWebUrl;
  static Future<String?>? _refreshInFlight;

  static String get webBaseUrl {
    if (customWebUrl != null && customWebUrl!.isNotEmpty) {
      return customWebUrl!;
    }
    return 'https://our-space-wheat.vercel.app';
  }

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    // TEMP FIX: Force local app to test against live server
    return 'https://ourspace-d81w.onrender.com/api';
  }

  static Future<String?> _refreshSessionToken() {
    if (_refreshInFlight != null) return _refreshInFlight!;
    _refreshInFlight = _performSessionRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  static Future<String?> _performSessionRefresh() async {
    try {
      final userInfoStr = await SecureStorageService.read('user_info');
      if (userInfoStr == null || userInfoStr.isEmpty) return null;
      final userInfo = Map<String, dynamic>.from(jsonDecode(userInfoStr));
      final password = (userInfo['password'] ?? '').toString().trim();
      final username = (userInfo['username'] ?? '').toString().trim();
      final email = (userInfo['email'] ?? '').toString().trim();
      final name = (userInfo['name'] ?? username.replaceFirst('@', '')).toString().trim();

      if (password.isEmpty || (username.isEmpty && email.isEmpty)) return null;

      // 1. Try login first
      try {
        final loginRes = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }),
        ).timeout(const Duration(seconds: 20));

        if (loginRes.statusCode == 200) {
          final data = jsonDecode(loginRes.body);
          final newToken = data['token']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            await SecureStorageService.write('auth_token', newToken);
            if (data['user'] is Map) {
              final updatedUser = Map<String, dynamic>.from(data['user']);
              updatedUser['password'] = password;
              await SecureStorageService.write('user_info', jsonEncode(updatedUser));
            }
            return newToken;
          }
        }
      } catch (_) {}

      // 2. Fallback: register if user only existed locally before DB was restored
      try {
        final derivedEmail = email.isNotEmpty
            ? email
            : '${username.replaceFirst('@', '').toLowerCase()}@ourspace.local';
        final regRes = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.isNotEmpty ? name : 'User',
            'email': derivedEmail,
            'password': password,
            'username': username.startsWith('@') ? username : '@$username',
          }),
        ).timeout(const Duration(seconds: 20));

        if (regRes.statusCode == 200 || regRes.statusCode == 201) {
          final data = jsonDecode(regRes.body);
          final newToken = data['token']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            await SecureStorageService.write('auth_token', newToken);
            if (data['user'] is Map) {
              final updatedUser = Map<String, dynamic>.from(data['user']);
              updatedUser['password'] = password;
              await SecureStorageService.write('user_info', jsonEncode(updatedUser));
            }
            return newToken;
          }
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  static Future<String?> _getValidToken(String endpoint) async {
    var token = await SecureStorageService.read('auth_token');
    if (!endpoint.startsWith('/auth/') &&
        (token == null || token.isEmpty || token.startsWith('token_local_'))) {
      final refreshed = await _refreshSessionToken();
      if (refreshed != null) token = refreshed;
    }
    return token;
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    var token = await _getValidToken(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    var response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      final refreshed = await _refreshSessionToken();
      if (refreshed != null && refreshed.isNotEmpty) {
        headers['Authorization'] = 'Bearer $refreshed';
        response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));
      }
    }

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'API Request failed');
    }
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    var token = await _getValidToken(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    var response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      final refreshed = await _refreshSessionToken();
      if (refreshed != null && refreshed.isNotEmpty) {
        headers['Authorization'] = 'Bearer $refreshed';
        response = await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));
      }
    }

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'API Request failed');
    }
    return data as Map<String, dynamic>;
  }

  static Future<dynamic> get(String endpoint) async {
    var token = await _getValidToken(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      final refreshed = await _refreshSessionToken();
      if (refreshed != null && refreshed.isNotEmpty) {
        headers['Authorization'] = 'Bearer $refreshed';
        response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        ).timeout(const Duration(seconds: 60));
      }
    }

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data is Map ? (data['error'] ?? 'API Request failed') : 'API Request failed');
    }
    return data;
  }
}
