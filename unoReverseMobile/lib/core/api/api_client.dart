import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;
}

class ApiClient {
  static const baseUrl = 'http://127.0.0.1:3000';
  static String? token;

  static Future<({int statusCode, dynamic body})> get(String path) {
    return _request('GET', path);
  }

  static Future<({int statusCode, dynamic body})> post(
    String path,
    Map<String, dynamic> payload,
  ) {
    return _request('POST', path, payload: payload);
  }

  static Future<({int statusCode, dynamic body})> put(
    String path,
    Map<String, dynamic> payload,
  ) {
    return _request('PUT', path, payload: payload);
  }

  static Future<({int statusCode, dynamic body})> delete(String path) {
    return _request('DELETE', path);
  }

  static Future<({int statusCode, dynamic body})> _request(
    String method,
    String path, {
    Map<String, dynamic>? payload,
  }) async {
    final url = '$baseUrl$path';
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
      final http.Response response;
      if (method == 'GET') {
        response = await http.get(Uri.parse(url), headers: headers);
      } else if (method == 'DELETE') {
        response = await http.delete(Uri.parse(url), headers: headers);
      } else if (method == 'PUT') {
        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(payload),
        );
      } else {
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(payload),
        );
      }

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

  static dynamic _decode(String body) {
    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String message(dynamic body, String fallback) {
    if (body is Map && body['message'] is String && body['message'].isNotEmpty) {
      return body['message'] as String;
    }
    return fallback;
  }

  static Map<String, dynamic> asMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    return {};
  }

  static List<Map<String, dynamic>> asList(dynamic body) {
    if (body is! List) {
      return [];
    }

    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
