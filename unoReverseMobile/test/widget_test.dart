import 'package:flutter_test/flutter_test.dart';
import 'package:uno_reverse/app.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/auth_repository.dart';
import 'package:uno_reverse/core/authentication/biometric_gateway.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/authentication/token_store.dart';
import 'package:uno_reverse/core/network/http_transport.dart';
import 'package:uno_reverse/core/security/secure_store.dart';

void main() {
  testWidgets('Login page shows email and password', (tester) async {
    final store = MemorySecureStore();
    final tokens = TokenStore(store);
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:3000',
      tokens: tokens,
      transport: PackageHttpTransport(),
    );
    ApiClient.install(client);
    final auth = AuthController(
      tokens: tokens,
      mpin: MpinStore(store),
      repository: AuthRepository(client),
      biometrics: _IdleBiometric(),
      client: client,
      observeLifecycle: false,
    );
    await auth.bootstrap();

    await tester.pumpWidget(UnoReverseApp(auth: auth));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

class _IdleBiometric implements BiometricGateway {
  @override
  Future<bool> authenticate({required String reason}) async => false;

  @override
  Future<bool> canAuthenticate() async => false;
}
