import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/biometric_gateway.dart';
import 'package:uno_reverse/core/authentication/auth_repository.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';
import 'package:uno_reverse/core/network/http_transport.dart';
import 'package:uno_reverse/core/security/secure_store.dart';
import 'package:uno_reverse/features/auth/login_page.dart';
import 'package:uno_reverse/features/auth/mpin_setup_page.dart';
import 'package:uno_reverse/features/auth/mpin_unlock_page.dart';
import 'package:uno_reverse/features/home/home_page.dart';

class UnoReverseApp extends StatelessWidget {
  const UnoReverseApp({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: auth,
      child: MaterialApp(
        navigatorKey: auth.navigatorKey,
        title: 'Core',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    switch (auth.phase) {
      case AuthPhase.initializing:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthPhase.unauthenticated:
      case AuthPhase.authenticating:
        return const LoginPage();
      case AuthPhase.mpinSetup:
        return const MpinSetupPage();
      case AuthPhase.locked:
        return const MpinUnlockPage();
      case AuthPhase.authenticated:
      case AuthPhase.loggingOut:
        return const HomePage();
    }
  }
}

Future<AuthController> createAuthController() async {
  final store = FlutterSecureStore();
  final tokens = TokenStore(store);
  final client = ApiClient(
    baseUrl: ApiClient.defaultBaseUrl,
    tokens: tokens,
    transport: PackageHttpTransport(),
  );
  ApiClient.install(client);
  final auth = AuthController(
    tokens: tokens,
    mpin: MpinStore(store),
    repository: AuthRepository(client),
    biometrics: LocalBiometricGateway(),
    client: client,
  );
  await auth.bootstrap();
  return auth;
}
