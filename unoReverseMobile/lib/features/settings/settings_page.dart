import 'package:flutter/material.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/features/auth/mpin_change_page.dart';
import 'package:uno_reverse/features/shell/app_bottom_nav.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    final enabled = await auth.mpin.biometricEnabled();
    final available = await auth.biometrics.canAuthenticate();
    if (!mounted) {
      return;
    }
    setState(() {
      _biometric = enabled;
      _biometricAvailable = available;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      await AuthScope.of(context).enableBiometric(value);
      if (mounted) {
        setState(() => _biometric = value);
      }
    } on MpinException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: shellCanvas,
      appBar: AppBar(
        backgroundColor: shellCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change M-PIN'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MpinChangePage()),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric unlock'),
            value: _biometric,
            onChanged: _biometricAvailable ? _toggleBiometric : null,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => AuthScope.of(context).logout(),
          ),
        ],
      ),
    );
  }
}
