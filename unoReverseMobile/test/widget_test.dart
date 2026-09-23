import 'package:flutter_test/flutter_test.dart';
import 'package:uno_reverse/app.dart';

void main() {
  testWidgets('Login page shows email and password', (tester) async {
    await tester.pumpWidget(const UnoReverseApp());

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
