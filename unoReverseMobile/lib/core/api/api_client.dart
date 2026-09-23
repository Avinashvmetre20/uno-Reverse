import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uno_reverse/core/constants/api_constants.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;
}

class ApiClient {
  static String? token;

  static Future<({int statusCode, Map<String, dynamic> body})> post(
    String path,
    Map<String, String> payload,
  ) {
    return _request('POST', path, payload: payload);
  }

  static Future<({int statusCode, Map<String, dynamic> body})> get(String path) {
    return _request('GET', path);
  }

  static Future<({int statusCode, Map<String, dynamic> body})> _request(
    String method,
    String path, {
    Map<String, String>? payload,
  }) async {
    final url = '${ApiConstants.baseUrl}$path';
    final start = DateTime.now();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    debugPrint('API CALL  $method $url');
    if (payload != null) {
      debugPrint('API BODY  $payload');
    }

    try {
      final response = method == 'GET'
          ? await http.get(Uri.parse(url), headers: headers)
          : await http.post(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(payload),
            );
      final ms = DateTime.now().difference(start).inMilliseconds;
      final body = _decode(response.body);

      debugPrint('API RESP  $method $path ${response.statusCode} ${ms}ms');
      debugPrint('API DATA  $body');

      return (statusCode: response.statusCode, body: body);
    } catch (error) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      debugPrint('API FAIL  $method $path ${ms}ms $error');
      throw ApiException('Cannot reach the server');
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  static String message(Map<String, dynamic> body, String fallback) {
    final value = body['message'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }
}
