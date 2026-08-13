import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final token = await SecureStorageService.read('auth_token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'API Request failed');
    }
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await SecureStorageService.read('auth_token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'API Request failed');
    }
    return data as Map<String, dynamic>;
  }
}
