import 'package:flutter/material.dart';
import 'package:uno_reverse/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = await createAuthController();
  runApp(UnoReverseApp(auth: auth));
}
