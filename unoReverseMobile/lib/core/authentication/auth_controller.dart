import 'package:flutter/widgets.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/auth_log.dart';
import 'package:uno_reverse/core/authentication/auth_policy.dart';
import 'package:uno_reverse/core/authentication/auth_repository.dart';
import 'package:uno_reverse/core/authentication/biometric_gateway.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing');
    return scope!.notifier!;
  }
}

enum AuthPhase {
  initializing,
  unauthenticated,
  authenticating,
  mpinSetup,
  locked,
  authenticated,
  loggingOut,
}

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController({
    required this.tokens,
    required this.mpin,
    required this.repository,
    required this.biometrics,
    required ApiClient client,
    this.observeLifecycle = true,
    DateTime Function()? clock,
  })  : _client = client,
        clock = clock ?? DateTime.now {
    _client.onSessionEnded = handleSessionEnded;
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  final TokenStore tokens;
  final MpinStore mpin;
  final AuthRepository repository;
  final BiometricGateway biometrics;
  final ApiClient _client;
  final bool observeLifecycle;
  final DateTime Function() clock;
  final navigatorKey = GlobalKey<NavigatorState>();

  AuthPhase phase = AuthPhase.initializing;
  String? notice;
  DateTime? _backgroundedAt;

  Future<void> bootstrap() async {
    await tokens.load();
    if (!tokens.hasRefresh) {
      _set(AuthPhase.unauthenticated);
      return;
    }

    if (!tokens.accessUsable) {
      try {
        await _client.send('GET', '/auth/profile');
      } on ApiException catch (error) {
        if (error.kind == ApiFailureKind.sessionExpired || error.kind == ApiFailureKind.authentication) {
          AuthLog.event('AUTH_SESSION_EXPIRED');
          await tokens.clear();
          notice = 'Your session has expired. Please log in again.';
          _set(AuthPhase.unauthenticated);
          return;
        }
      }
    }

    if (!tokens.hasRefresh) {
      _set(AuthPhase.unauthenticated);
      return;
    }

    await _requireLocalUnlock();
  }

  Future<void> login(String email, String password) async {
    AuthLog.event('AUTH_LOGIN_STARTED');
    _set(AuthPhase.authenticating);
    try {
      final session = await repository.login(email: email, password: password);
      await tokens.save(session);
      AuthLog.event('AUTH_LOGIN_SUCCESS');
      await _requireLocalUnlock();
    } on ApiException {
      AuthLog.event('AUTH_LOGIN_FAILED');
      _set(AuthPhase.unauthenticated);
      rethrow;
    }
  }

  Future<void> setupPin(String pin, String confirm) async {
    final email = tokens.email;
    if (email == null) {
      throw MpinException('Your session has expired. Please log in again.');
    }
    await mpin.setup(email, pin, confirm);
    _set(AuthPhase.authenticated);
  }

  Future<void> unlockWithPin(String pin) async {
    final email = tokens.email;
    if (email == null) {
      throw MpinException('Your session has expired. Please log in again.');
    }
    try {
      await mpin.verify(email, pin);
    } on MpinException {
      AuthLog.event('AUTH_MPIN_FAILED');
      rethrow;
    }
    _set(AuthPhase.authenticated);
  }

  Future<bool> unlockWithBiometric() async {
    if (!await mpin.biometricEnabled() || !await biometrics.canAuthenticate()) {
      return false;
    }
    final ok = await biometrics.authenticate(reason: 'Unlock Core');
    if (!ok) {
      return false;
    }
    _set(AuthPhase.authenticated);
    return true;
  }

  Future<void> enableBiometric(bool enabled) async {
    if (enabled && !await biometrics.canAuthenticate()) {
      throw MpinException('Biometric unlock is not available on this device.');
    }
    await mpin.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> changePin({
    required String current,
    required String next,
    required String confirm,
  }) async {
    final email = tokens.email;
    if (email == null) {
      throw MpinException('Your session has expired. Please log in again.');
    }
    await mpin.change(email: email, current: current, next: next, confirm: confirm);
  }

  Future<void> resetPinWithPassword(String password) async {
    final email = tokens.email;
    if (email == null) {
      throw MpinException('Your session has expired. Please log in again.');
    }

    final previousRefresh = tokens.refreshToken;
    if (previousRefresh != null) {
      try {
        await repository.logout(previousRefresh);
      } on ApiException {
        // A failed revoke must not block password recovery.
      }
    }

    final session = await repository.login(email: email, password: password);
    await tokens.save(session);
    await mpin.clear();
    _set(AuthPhase.mpinSetup);
  }

  Future<void> logout() async {
    AuthLog.event('AUTH_LOGOUT');
    _set(AuthPhase.loggingOut);
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null) {
      try {
        await repository.logout(refreshToken);
      } on ApiException {
        // Local credentials are still cleared when the server cannot be reached.
      }
    }
    await tokens.clear();
    _popToRoot();
    _set(AuthPhase.unauthenticated);
  }

  void handleSessionEnded() {
    if (phase == AuthPhase.unauthenticated) {
      return;
    }
    notice = 'Your session has expired. Please log in again.';
    _popToRoot();
    _set(AuthPhase.unauthenticated);
  }

  void clearNotice() {
    notice = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= clock();
      return;
    }

    if (state != AppLifecycleState.resumed || phase != AuthPhase.authenticated) {
      return;
    }

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) {
      return;
    }
    if (clock().difference(backgroundedAt) >= AuthPolicy.backgroundLock) {
      _set(AuthPhase.locked);
    }
  }

  @override
  void dispose() {
    if (observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  Future<void> _requireLocalUnlock() async {
    final email = tokens.email;
    if (email == null || !tokens.hasRefresh) {
      _set(AuthPhase.unauthenticated);
      return;
    }
    if (await mpin.isConfiguredFor(email)) {
      _set(AuthPhase.locked);
      return;
    }
    _set(AuthPhase.mpinSetup);
  }

  void _set(AuthPhase value) {
    phase = value;
    notifyListeners();
  }

  void _popToRoot() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
