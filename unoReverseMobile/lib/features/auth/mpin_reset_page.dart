import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/api_client.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/security/screen_security.dart';

class MpinResetPage extends StatefulWidget {
  const MpinResetPage({super.key});

  @override
  State<MpinResetPage> createState() => _MpinResetPageState();
}

class _MpinResetPageState extends State<MpinResetPage> {
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).resetPinWithPassword(_password.text);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on MpinException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Reset M-PIN')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Confirm your password to create a new M-PIN.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Please wait' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
