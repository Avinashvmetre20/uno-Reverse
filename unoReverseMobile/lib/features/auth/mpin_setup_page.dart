import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/security/screen_security.dart';

class MpinSetupPage extends StatefulWidget {
  const MpinSetupPage({super.key});

  @override
  State<MpinSetupPage> createState() => _MpinSetupPageState();
}

class _MpinSetupPageState extends State<MpinSetupPage> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _confirmStep = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_confirmStep) {
      if (_pin.text.length != 4) {
        setState(() => _error = 'Enter a 4-digit M-PIN');
        return;
      }
      setState(() => _confirmStep = true);
      return;
    }

    try {
      await AuthScope.of(context).setupPin(_pin.text, _confirm.text);
    } on MpinException catch (error) {
      setState(() => _error = error.message);
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
                      _confirmStep ? 'Confirm M-PIN' : 'Set M-PIN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirmStep
                          ? 'Enter the same 4-digit M-PIN again'
                          : 'Create a 4-digit M-PIN for quick access',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      key: ValueKey(_confirmStep),
                      controller: _confirmStep ? _confirm : _pin,
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
                      onPressed: _submit,
                      child: Text(_confirmStep ? 'Confirm' : 'Continue'),
                    ),
                    if (_confirmStep)
                      TextButton(
                        onPressed: () {
                          _confirm.clear();
                          setState(() {
                            _confirmStep = false;
                            _error = null;
                          });
                        },
                        child: const Text('Back'),
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
