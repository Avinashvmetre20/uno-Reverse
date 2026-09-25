import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class HttpResult {
  const HttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final dynamic body;
}

class HttpTransportException implements Exception {
  HttpTransportException._(this.kind);

  final String kind;

  factory HttpTransportException.timeout() => HttpTransportException._('timeout');

  factory HttpTransportException.network() => HttpTransportException._('network');
}

abstract class HttpTransport {
  Future<HttpResult> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
    required Duration timeout,
  });
}

class PackageHttpTransport implements HttpTransport {
  PackageHttpTransport({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<HttpResult> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
    required Duration timeout,
  }) async {
    try {
      final response = await _dispatch(method, url, headers, body).timeout(timeout);
      return HttpResult(statusCode: response.statusCode, body: _decode(response.body));
    } on TimeoutException {
      throw HttpTransportException.timeout();
    } on SocketException {
      throw HttpTransportException.network();
    } on http.ClientException {
      throw HttpTransportException.network();
    }
  }

  Future<http.Response> _dispatch(
    String method,
    Uri url,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case 'GET':
        return _client.get(url, headers: headers);
      case 'DELETE':
        return _client.delete(url, headers: headers);
      case 'PUT':
        return _client.put(url, headers: headers, body: body);
      default:
        return _client.post(url, headers: headers, body: body);
    }
  }

  dynamic _decode(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
