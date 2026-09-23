import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/storage/mpin_storage.dart';
import 'package:uno_reverse/features/home/home_page.dart';

class MpinSetupPage extends StatefulWidget {
  const MpinSetupPage({super.key, required this.email});

  final String email;

  @override
  State<MpinSetupPage> createState() => _MpinSetupPageState();
}

class _MpinSetupPageState extends State<MpinSetupPage> {
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _confirmStep = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _error = null);

    if (!_confirmStep) {
      if (_pin.text.length != 4) {
        setState(() => _error = 'Enter a 4-digit M-PIN');
        return;
      }
      setState(() => _confirmStep = true);
      return;
    }

    if (_confirmPin.text.length != 4) {
      setState(() => _error = 'Confirm your 4-digit M-PIN');
      return;
    }

    if (_confirmPin.text != _pin.text) {
      setState(() => _error = 'M-PIN does not match');
      return;
    }

    await MpinStorage.save(widget.email, _pin.text);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _confirmStep ? _confirmPin : _pin;

    return Scaffold(
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
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: controller,
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
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() => _error = null);
                      }
                    },
                    onSubmitted: (_) => _continue(),
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
                    onPressed: _continue,
                    child: Text(_confirmStep ? 'Confirm' : 'Continue'),
                  ),
                  if (_confirmStep) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _confirmPin.clear();
                        setState(() {
                          _confirmStep = false;
                          _error = null;
                        });
                      },
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
