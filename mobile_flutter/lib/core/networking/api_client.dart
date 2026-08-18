import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient {
  static String? customBaseUrl;
  static String? customWebUrl;

  static String get webBaseUrl {
    if (customWebUrl != null && customWebUrl!.isNotEmpty) {
      return customWebUrl!;
    }
    return 'https://ourspace-web.onrender.com';
  }

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    return 'https://ourspace-backend.onrender.com/api';
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
    ).timeout(const Duration(seconds: 3));

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
    ).timeout(const Duration(seconds: 3));

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'API Request failed');
    }
    return data as Map<String, dynamic>;
  }
}
