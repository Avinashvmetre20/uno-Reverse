import 'package:uno_reverse/core/authentication/auth_policy.dart';
import 'package:uno_reverse/core/security/secure_store.dart';

class AuthKeys {
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
  static const accessExpiresAt = 'auth.access_expires_at';
  static const sessionId = 'auth.session_id';
  static const email = 'auth.email';
}

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.sessionId,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final String sessionId;
  final String email;

  factory StoredSession.fromLogin({
    required Map<String, dynamic> body,
    required String email,
    required DateTime now,
  }) {
    final access = body['accessToken'] ?? body['token'];
    final refresh = body['refreshToken'];
    final sessionId = body['sessionId'];
    final expiresIn = body['expiresIn'];

    if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
      throw const FormatException('missing session tokens');
    }
    if (sessionId is! String || sessionId.isEmpty) {
      throw const FormatException('missing session id');
    }

    final seconds = expiresIn is num ? expiresIn.toInt() : 900;
    return StoredSession(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: now.add(Duration(seconds: seconds)),
      sessionId: sessionId,
      email: email,
    );
  }
}

class TokenStore {
  TokenStore(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final SecureStore _store;
  final DateTime Function() _clock;

  String? accessToken;
  String? refreshToken;
  DateTime? accessExpiresAt;
  String? sessionId;
  String? email;

  bool get hasRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  bool get accessUsable {
    final expiry = accessExpiresAt;
    final token = accessToken;
    if (token == null || token.isEmpty || expiry == null) {
      return false;
    }
    return expiry.isAfter(_clock().add(AuthPolicy.accessSkew));
  }

  Future<void> load() async {
    accessToken = await _store.read(AuthKeys.accessToken);
    refreshToken = await _store.read(AuthKeys.refreshToken);
    sessionId = await _store.read(AuthKeys.sessionId);
    email = await _store.read(AuthKeys.email);
    final rawExpiry = await _store.read(AuthKeys.accessExpiresAt);
    accessExpiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
  }

  Future<void> save(StoredSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    accessExpiresAt = session.accessExpiresAt;
    sessionId = session.sessionId;
    email = session.email;
    await _store.write(AuthKeys.accessToken, session.accessToken);
    await _store.write(AuthKeys.refreshToken, session.refreshToken);
    await _store.write(AuthKeys.sessionId, session.sessionId);
    await _store.write(AuthKeys.email, session.email);
    await _store.write(AuthKeys.accessExpiresAt, session.accessExpiresAt.toIso8601String());
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    accessExpiresAt = null;
    sessionId = null;
    email = null;
    await _store.delete(AuthKeys.accessToken);
    await _store.delete(AuthKeys.refreshToken);
    await _store.delete(AuthKeys.accessExpiresAt);
    await _store.delete(AuthKeys.sessionId);
    await _store.delete(AuthKeys.email);
  }
}
