import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uno_reverse/core/authentication/auth_log.dart';
import 'package:uno_reverse/core/authentication/auth_policy.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';
import 'package:uno_reverse/core/network/http_transport.dart';

enum ApiFailureKind {
  authentication,
  sessionExpired,
  network,
  timeout,
  server,
  validation,
  unknown,
}

class ApiException implements Exception {
  ApiException(this.message, {this.kind = ApiFailureKind.unknown, this.statusCode, this.code});

  final String message;
  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiResult {
  const ApiResult({required this.statusCode, required this.body});

  final int statusCode;
  final dynamic body;
}

enum _RefreshOutcome { success, authFailed, unavailable }

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStore tokens,
    required HttpTransport transport,
    DateTime Function()? clock,
  })  : _tokens = tokens,
        _transport = transport,
        _clock = clock ?? DateTime.now;

  /// Production API on Render.
  /// Override with --dart-define=API_BASE_URL=http://127.0.0.1:3000 for a local server.
  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }
    return 'https://core-backend-ho5o.onrender.com';
  }

  static ApiClient? _instance;

  static ApiClient get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('ApiClient is not ready');
    }
    return value;
  }

  static void install(ApiClient client) {
    _instance = client;
  }

  final String baseUrl;
  final TokenStore _tokens;
  final HttpTransport _transport;
  final DateTime Function() _clock;

  void Function()? onSessionEnded;

  Future<_RefreshOutcome>? _refreshing;

  static Future<ApiResult> get(String path) => instance.send('GET', path);

  static Future<ApiResult> post(String path, Map<String, dynamic> payload) {
    return instance.send('POST', path, payload: payload);
  }

  static Future<ApiResult> put(String path, Map<String, dynamic> payload) {
    return instance.send('PUT', path, payload: payload);
  }

  static Future<ApiResult> delete(String path) => instance.send('DELETE', path);

  Future<ApiResult> send(
    String method,
    String path, {
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    bool authenticated = true,
    bool allowRefresh = true,
  }) async {
    _rejectInsecureProductionUrl();

    if (authenticated && allowRefresh && !_tokens.accessUsable && _tokens.hasRefresh) {
      final outcome = await _refreshOnce();
      if (outcome == _RefreshOutcome.authFailed) {
        await _endSession();
        throw ApiException(
          'Your session has expired. Please log in again.',
          kind: ApiFailureKind.sessionExpired,
          statusCode: 401,
        );
      }
      if (outcome == _RefreshOutcome.unavailable && !_tokens.accessUsable) {
        throw ApiException(
          'Unable to connect. Please check your internet connection.',
          kind: ApiFailureKind.network,
        );
      }
    }

    try {
      final result = await _dispatch(method, path, payload: payload, headers: headers, authenticated: authenticated);
      if (result.statusCode != 401 || !authenticated || !allowRefresh) {
        return result;
      }

      final outcome = await _refreshOnce();
      if (outcome == _RefreshOutcome.success) {
        return await _dispatch(
          method,
          path,
          payload: payload,
          headers: headers,
          authenticated: true,
        );
      }
      if (outcome == _RefreshOutcome.authFailed) {
        await _endSession();
        throw ApiException(
          'Your session has expired. Please log in again.',
          kind: ApiFailureKind.sessionExpired,
          statusCode: 401,
        );
      }
      throw ApiException(
        'Unable to connect. Please check your internet connection.',
        kind: ApiFailureKind.network,
        statusCode: result.statusCode,
      );
    } on HttpTransportException catch (error) {
      debugPrint('API FAIL  $method $path ${error.kind}');
      throw _transportError(error);
    }
  }

  Future<ApiResult> _dispatch(
    String method,
    String path, {
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    required bool authenticated,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
      if (authenticated && _tokens.accessToken != null) 'Authorization': 'Bearer ${_tokens.accessToken}',
    };

    debugPrint('API CALL  $method $path');
    if (payload != null) {
      debugPrint('API BODY  ${_redacted(payload)}');
    }

    final started = _clock();
    final result = await _transport.send(
      method: method,
      url: url,
      headers: requestHeaders,
      body: payload == null ? null : jsonEncode(payload),
      timeout: AuthPolicy.requestTimeout,
    );
    final ms = _clock().difference(started).inMilliseconds;
    debugPrint('API RESP  $method $path ${result.statusCode} ${ms}ms');
    return ApiResult(statusCode: result.statusCode, body: result.body);
  }

  Future<_RefreshOutcome> _refreshOnce() {
    final existing = _refreshing;
    if (existing != null) {
      return existing;
    }
    final flight = _refresh();
    _refreshing = flight;
    return flight.whenComplete(() {
      if (identical(_refreshing, flight)) {
        _refreshing = null;
      }
    });
  }

  Future<_RefreshOutcome> _refresh() async {
    final refreshToken = _tokens.refreshToken;
    final email = _tokens.email;
    if (refreshToken == null || email == null) {
      return _RefreshOutcome.authFailed;
    }

    AuthLog.event('AUTH_REFRESH_STARTED');
    try {
      final result = await _transport.send(
        method: 'POST',
        url: Uri.parse('$baseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
        timeout: AuthPolicy.requestTimeout,
      );

      if (result.statusCode == 401 || result.statusCode == 403) {
        AuthLog.event('AUTH_REFRESH_FAILED');
        return _RefreshOutcome.authFailed;
      }
      if (result.statusCode >= 500 || result.statusCode == 0) {
        AuthLog.event('AUTH_REFRESH_FAILED');
        return _RefreshOutcome.unavailable;
      }
      if (result.statusCode != 200) {
        AuthLog.event('AUTH_REFRESH_FAILED');
        return _RefreshOutcome.authFailed;
      }

      final session = StoredSession.fromLogin(
        body: _asMap(result.body),
        email: email,
        now: _clock(),
      );
      await _tokens.save(session);
      AuthLog.event('AUTH_REFRESH_SUCCESS');
      return _RefreshOutcome.success;
    } on FormatException {
      AuthLog.event('AUTH_REFRESH_FAILED');
      return _RefreshOutcome.authFailed;
    } on HttpTransportException {
      AuthLog.event('AUTH_REFRESH_FAILED');
      return _RefreshOutcome.unavailable;
    }
  }

  Future<void> _endSession() async {
    AuthLog.event('AUTH_SESSION_EXPIRED');
    await _tokens.clear();
    onSessionEnded?.call();
  }

  void _rejectInsecureProductionUrl() {
    if (kReleaseMode && baseUrl.startsWith('http://')) {
      throw ApiException(
        'Something went wrong. Please try again.',
        kind: ApiFailureKind.unknown,
      );
    }
  }

  ApiException _transportError(HttpTransportException error) {
    if (error.kind == 'timeout') {
      return ApiException(
        'Unable to connect. Please check your internet connection.',
        kind: ApiFailureKind.timeout,
      );
    }
    return ApiException(
      'Unable to connect. Please check your internet connection.',
      kind: ApiFailureKind.network,
    );
  }

  static Map<String, dynamic> _redacted(Map<String, dynamic> payload) {
    const hidden = {'password', 'refreshToken', 'token', 'accessToken', 'pin', 'mpin', 'otp'};
    return payload.map((key, value) => MapEntry(key, hidden.contains(key) ? '[REDACTED]' : value));
  }

  static String message(dynamic body, String fallback) {
    if (body is Map && body['message'] is String && (body['message'] as String).isNotEmpty) {
      return body['message'] as String;
    }
    return fallback;
  }

  static Map<String, dynamic> asMap(dynamic body) => _asMap(body);

  static Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return {};
  }

  static List<Map<String, dynamic>> asList(dynamic body) {
    if (body is! List) {
      return [];
    }
    return body.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static ApiException failure(ApiResult result, String fallback, {ApiFailureKind? kind}) {
    final status = result.statusCode;
    final ApiFailureKind resolved;
    if (kind != null) {
      resolved = kind;
    } else if (status == 401 || status == 403) {
      resolved = ApiFailureKind.authentication;
    } else if (status == 400 || status == 409) {
      resolved = ApiFailureKind.validation;
    } else if (status >= 500) {
      resolved = ApiFailureKind.server;
    } else {
      resolved = ApiFailureKind.unknown;
    }

    final message = status >= 500
        ? 'Something went wrong. Please try again.'
        : ApiClient.message(result.body, fallback);

    return ApiException(
      message,
      kind: resolved,
      statusCode: status,
      code: result.body is Map ? result.body['code'] as String? : null,
    );
  }
}
