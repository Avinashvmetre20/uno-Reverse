import 'package:flutter/foundation.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<StoredSession> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.send(
      'POST',
      '/auth/login',
      payload: {
        'email': email,
        'password': password,
      },
      headers: {'X-Client-Platform': _platform},
      authenticated: false,
      allowRefresh: false,
    );

    if (result.statusCode != 200) {
      throw ApiClient.failure(result, 'Unable to login');
    }

    try {
      return StoredSession.fromLogin(
        body: ApiClient.asMap(result.body),
        email: email,
        now: DateTime.now(),
      );
    } on FormatException {
      throw ApiException(
        'Something went wrong. Please try again.',
        kind: ApiFailureKind.server,
      );
    }
  }

  Future<void> logout(String refreshToken) async {
    final result = await _client.send(
      'POST',
      '/auth/logout',
      payload: {'refreshToken': refreshToken},
      authenticated: false,
      allowRefresh: false,
    );

    if (result.statusCode != 200) {
      throw ApiClient.failure(result, 'Unable to logout');
    }
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name.toLowerCase();
  }
}
