import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';
import 'package:uno_reverse/features/auth/login_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          AuthApi.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        },
        child: const Text('Logout'),
      ),
    );
  }
}
