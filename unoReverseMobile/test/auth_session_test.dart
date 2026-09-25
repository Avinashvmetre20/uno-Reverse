import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/auth_policy.dart';
import 'package:uno_reverse/core/authentication/auth_repository.dart';
import 'package:uno_reverse/core/authentication/biometric_gateway.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';
import 'package:uno_reverse/core/network/http_transport.dart';
import 'package:uno_reverse/core/security/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('token store', () {
    test('saves, replaces, and clears session secrets', () async {
      final store = MemorySecureStore();
      final tokens = TokenStore(store);
      final first = _session(access: 'a', refresh: 'r1');
      await tokens.save(first);
      await tokens.load();
      expect(tokens.accessToken, 'a');
      expect(tokens.refreshToken, 'r1');

      await tokens.save(_session(access: 'b', refresh: 'r2'));
      expect(tokens.refreshToken, 'r2');
      expect(store.values[AuthKeys.refreshToken], 'r2');

      await tokens.clear();
      expect(tokens.hasRefresh, isFalse);
      expect(store.values, isEmpty);
    });
  });

  group('m-pin', () {
    test('setup, verify, reject, lock, and change', () async {
      var now = DateTime(2026, 1, 1, 12);
      final store = MemorySecureStore();
      final mpin = MpinStore(store, clock: () => now, random: _FixedRandom());

      await mpin.setup('a@b.com', '1357', '1357');
      expect(await mpin.isConfiguredFor('a@b.com'), isTrue);
      expect(store.values.values.contains('1357'), isFalse);

      await mpin.verify('a@b.com', '1357');

      for (var i = 0; i < AuthPolicy.maxPinAttempts; i++) {
        await expectLater(mpin.verify('a@b.com', '9991'), throwsA(isA<MpinException>()));
      }
      await expectLater(
        mpin.verify('a@b.com', '1357'),
        throwsA(predicate((error) => error is MpinException && error.message.contains('Too many'))),
      );

      now = now.add(AuthPolicy.pinLockout);
      await mpin.verify('a@b.com', '1357');
      await mpin.change(email: 'a@b.com', current: '1357', next: '2468', confirm: '2468');
      await mpin.verify('a@b.com', '2468');
      expect(store.values.values.contains('2468'), isFalse);
      await expectLater(mpin.setup('a@b.com', '1234', '1234'), throwsA(isA<MpinException>()));
    });
  });

  group('api client refresh', () {
    test('retries one 401 after a single refresh', () async {
      final harness = _Harness();
      harness.transport.handler = (request) {
        if (request.path == '/auth/refresh') {
          harness.refreshCalls++;
          return _ok({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'expiresIn': 900,
            'sessionId': 's1',
          });
        }
        if (request.authorization == 'Bearer old-access') {
          return _status(401, {'message': 'expired', 'code': 'ACCESS_EXPIRED'});
        }
        return _ok({'ok': true});
      };

      final result = await harness.client.send('GET', '/banks');
      expect(result.statusCode, 200);
      expect(harness.refreshCalls, 1);
      expect(harness.tokens.accessToken, 'new-access');
      expect(harness.tokens.refreshToken, 'new-refresh');
    });

    test('concurrent 401s share one refresh', () async {
      final harness = _Harness();
      harness.transport.handler = (request) async {
        if (request.path == '/auth/refresh') {
          harness.refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return _ok({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'expiresIn': 900,
            'sessionId': 's1',
          });
        }
        if (request.authorization == 'Bearer old-access') {
          return _status(401, {'code': 'ACCESS_EXPIRED'});
        }
        return _ok([]);
      };

      final results = await Future.wait([
        harness.client.send('GET', '/banks'),
        harness.client.send('GET', '/cards'),
        harness.client.send('GET', '/transactions'),
      ]);
      expect(results.every((result) => result.statusCode == 200), isTrue);
      expect(harness.refreshCalls, 1);
    });

    test('invalid refresh ends the session and does not loop', () async {
      final harness = _Harness();
      var ended = 0;
      harness.client.onSessionEnded = () => ended++;
      harness.transport.handler = (request) {
        if (request.path == '/auth/refresh') {
          harness.refreshCalls++;
          return _status(401, {'code': 'REFRESH_TOKEN_INVALID'});
        }
        return _status(401, {'code': 'ACCESS_EXPIRED'});
      };

      await expectLater(
        harness.client.send('GET', '/banks'),
        throwsA(predicate((error) => error is ApiException && error.kind == ApiFailureKind.sessionExpired)),
      );
      expect(harness.refreshCalls, 1);
      expect(harness.tokens.hasRefresh, isFalse);
      expect(ended, 1);
    });

    test('refresh server failure keeps credentials', () async {
      final harness = _Harness();
      harness.transport.handler = (request) {
        if (request.path == '/auth/refresh') {
          return _status(500, {'message': 'db down'});
        }
        return _status(401, {'code': 'ACCESS_EXPIRED'});
      };

      await expectLater(harness.client.send('GET', '/banks'), throwsA(isA<ApiException>()));
      expect(harness.tokens.refreshToken, 'old-refresh');
    });

    test('refresh network failure keeps credentials', () async {
      final harness = _Harness();
      harness.transport.handler = (request) {
        if (request.path == '/auth/refresh') {
          throw HttpTransportException.network();
        }
        return _status(401, {'code': 'ACCESS_EXPIRED'});
      };

      await expectLater(
        harness.client.send('GET', '/banks'),
        throwsA(predicate((error) => error is ApiException && error.kind == ApiFailureKind.network)),
      );
      expect(harness.tokens.refreshToken, 'old-refresh');
    });
  });

  group('auth controller', () {
    test('login failure stays signed out', () async {
      final harness = await _controller();
      harness.transport.handler = (_) => _status(401, {'message': 'Invalid email or password'});

      await expectLater(
        harness.auth.login('a@b.com', 'secret'),
        throwsA(isA<ApiException>()),
      );
      expect(harness.auth.phase, AuthPhase.unauthenticated);
      expect(harness.auth.tokens.hasRefresh, isFalse);
    });

    test('login success requires m-pin setup, then unlocks', () async {
      final harness = await _controller();
      harness.transport.handler = (request) {
        if (request.path == '/auth/login') {
          return _ok({
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'expiresIn': 900,
            'sessionId': 'session',
          });
        }
        if (request.path == '/auth/logout') {
          return _ok({'message': 'Logged out'});
        }
        return _ok({});
      };

      await harness.auth.login('a@b.com', 'secret');
      expect(harness.auth.phase, AuthPhase.mpinSetup);
      await harness.auth.setupPin('1357', '1357');
      expect(harness.auth.phase, AuthPhase.authenticated);

      harness.auth.didChangeAppLifecycleState(AppLifecycleState.paused);
      harness.now = harness.now.add(AuthPolicy.backgroundLock);
      harness.auth.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(harness.auth.phase, AuthPhase.locked);

      await harness.auth.logout();
      expect(harness.auth.phase, AuthPhase.unauthenticated);
      expect(harness.auth.tokens.hasRefresh, isFalse);
    });

    test('startup refresh failure returns to login', () async {
      final store = MemorySecureStore();
      final tokens = TokenStore(store, clock: () => DateTime.now());
      await tokens.save(_session(access: 'old', refresh: 'gone', expiresIn: -10));
      final transport = _ScriptTransport();
      transport.handler = (request) {
        if (request.path == '/auth/refresh') {
          return _status(401, {'code': 'REFRESH_TOKEN_INVALID'});
        }
        return _status(401, {'code': 'ACCESS_EXPIRED'});
      };
      final client = ApiClient(baseUrl: 'http://127.0.0.1:3000', tokens: tokens, transport: transport);
      final auth = AuthController(
        tokens: tokens,
        mpin: MpinStore(store),
        repository: AuthRepository(client),
        biometrics: _FakeBiometric(),
        client: client,
        observeLifecycle: false,
      );
      await auth.bootstrap();
      expect(auth.phase, AuthPhase.unauthenticated);
      expect(tokens.hasRefresh, isFalse);
    });

    test('biometric unlock succeeds or falls back', () async {
      final success = _FakeBiometric(available: true, accepts: true);
      final harness = await _controller(biometrics: success);
      await harness.auth.mpin.setup('a@b.com', '1357', '1357');
      harness.auth.tokens.email = 'a@b.com';
      await harness.auth.enableBiometric(true);
      harness.auth.phase = AuthPhase.locked;
      expect(await harness.auth.unlockWithBiometric(), isTrue);
      expect(harness.auth.phase, AuthPhase.authenticated);

      final failure = _FakeBiometric(available: true, accepts: false);
      final locked = await _controller(biometrics: failure);
      await locked.auth.mpin.setup('a@b.com', '1357', '1357');
      locked.auth.tokens.email = 'a@b.com';
      await locked.auth.enableBiometric(true);
      locked.auth.phase = AuthPhase.locked;
      expect(await locked.auth.unlockWithBiometric(), isFalse);
      expect(locked.auth.phase, AuthPhase.locked);
    });
  });
}

StoredSession _session({
  required String access,
  required String refresh,
  int expiresIn = 900,
}) {
  return StoredSession(
    accessToken: access,
    refreshToken: refresh,
    accessExpiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    sessionId: 's1',
    email: 'a@b.com',
  );
}

class _FixedRandom implements Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.5;
  @override
  int nextInt(int max) => 7;
}

class _FakeBiometric implements BiometricGateway {
  _FakeBiometric({this.available = false, this.accepts = true});

  bool available;
  bool accepts;

  @override
  Future<bool> authenticate({required String reason}) async => accepts;

  @override
  Future<bool> canAuthenticate() async => available;
}

class _RecordedRequest {
  _RecordedRequest({required this.path, required this.authorization});
  final String path;
  final String? authorization;
}

class _ScriptTransport implements HttpTransport {
  FutureOr<HttpResult> Function(_RecordedRequest request)? handler;

  @override
  Future<HttpResult> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
    required Duration timeout,
  }) async {
    final handler = this.handler;
    if (handler == null) {
      return _status(500, {});
    }
    final result = handler(_RecordedRequest(path: url.path, authorization: headers['Authorization']));
    return Future.value(result);
  }
}

class _Harness {
  _Harness() {
    transport = _ScriptTransport();
    tokens = TokenStore(MemorySecureStore());
    tokens.accessToken = 'old-access';
    tokens.refreshToken = 'old-refresh';
    tokens.email = 'a@b.com';
    tokens.sessionId = 's1';
    tokens.accessExpiresAt = DateTime.now().add(const Duration(minutes: 5));
    client = ApiClient(baseUrl: 'http://127.0.0.1:3000', tokens: tokens, transport: transport);
  }

  late final _ScriptTransport transport;
  late final TokenStore tokens;
  late final ApiClient client;
  int refreshCalls = 0;
}

class _Clock {
  DateTime now = DateTime(2026, 1, 1, 12);
}

class _ControllerHarness {
  _ControllerHarness(this.auth, this.transport, this.biometrics, this.clock);
  final AuthController auth;
  final _ScriptTransport transport;
  final _FakeBiometric biometrics;
  final _Clock clock;
  DateTime get now => clock.now;
  set now(DateTime value) => clock.now = value;
}

Future<_ControllerHarness> _controller({_FakeBiometric? biometrics}) async {
  final store = MemorySecureStore();
  final tokens = TokenStore(store);
  final transport = _ScriptTransport();
  final biometric = biometrics ?? _FakeBiometric();
  final clock = _Clock();
  final client = ApiClient(baseUrl: 'http://127.0.0.1:3000', tokens: tokens, transport: transport);
  final auth = AuthController(
    tokens: tokens,
    mpin: MpinStore(store, random: _FixedRandom()),
    repository: AuthRepository(client),
    biometrics: biometric,
    client: client,
    observeLifecycle: false,
    clock: () => clock.now,
  );
  await auth.bootstrap();
  return _ControllerHarness(auth, transport, biometric, clock);
}

HttpResult _ok(dynamic body) => HttpResult(statusCode: 200, body: body);

HttpResult _status(int code, dynamic body) => HttpResult(statusCode: code, body: body);
