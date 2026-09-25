import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/security/screen_security.dart';
import 'package:uno_reverse/features/auth/mpin_reset_page.dart';

class MpinUnlockPage extends StatefulWidget {
  const MpinUnlockPage({super.key});

  @override
  State<MpinUnlockPage> createState() => _MpinUnlockPageState();
}

class _MpinUnlockPageState extends State<MpinUnlockPage> {
  final _pin = TextEditingController();
  String? _error;
  bool _canUseBiometric = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareBiometric());
  }

  Future<void> _prepareBiometric() async {
    final auth = AuthScope.of(context);
    final enabled = await auth.mpin.biometricEnabled();
    final available = await auth.biometrics.canAuthenticate();
    if (!mounted) {
      return;
    }
    setState(() => _canUseBiometric = enabled && available);
    if (enabled && available) {
      await auth.unlockWithBiometric();
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await AuthScope.of(context).unlockWithPin(_pin.text);
    } on MpinException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter M-PIN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Unlock Core', textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _pin,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 12),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(_busy ? 'Please wait' : 'Continue'),
                    ),
                    if (_canUseBiometric)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => AuthScope.of(context).unlockWithBiometric(),
                        child: const Text('Use biometrics'),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MpinResetPage()),
                              );
                            },
                      child: const Text('Forgot M-PIN?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
