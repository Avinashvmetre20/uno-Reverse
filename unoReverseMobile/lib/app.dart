import 'package:flutter/material.dart';
import 'package:uno_reverse/features/auth/login_page.dart';

class UnoReverseApp extends StatelessWidget {
  const UnoReverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uno Reverse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
