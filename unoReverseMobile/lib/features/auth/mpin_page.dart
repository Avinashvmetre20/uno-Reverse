import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/storage/mpin_storage.dart';
import 'package:uno_reverse/features/home/home_page.dart';

enum MpinMode { setup, verify }

class MpinPage extends StatefulWidget {
  const MpinPage({
    super.key,
    required this.email,
    required this.mode,
  });

  final String email;
  final MpinMode mode;

  @override
  State<MpinPage> createState() => _MpinPageState();
}

class _MpinPageState extends State<MpinPage> {
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _confirmStep = false;
  bool _loading = false;
  String? _error;

  bool get _isSetup => widget.mode == MpinMode.setup;

  @override
  void dispose() {
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_isSetup) {
      await _handleSetup();
      return;
    }

    await _handleVerify();
  }

  Future<void> _handleSetup() async {
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
    _goHome();
  }

  Future<void> _handleVerify() async {
    if (_pin.text.length != 4) {
      setState(() => _error = 'Enter your 4-digit M-PIN');
      return;
    }

    setState(() => _loading = true);
    final ok = await MpinStorage.verify(widget.email, _pin.text);
    if (!mounted) {
      return;
    }

    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Incorrect M-PIN';
      });
      return;
    }

    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _isSetup && _confirmStep ? _confirmPin : _pin;
    final title = !_isSetup
        ? 'Enter M-PIN'
        : (_confirmStep ? 'Confirm M-PIN' : 'Set M-PIN');
    final subtitle = !_isSetup
        ? 'Unlock Uno Reverse'
        : (_confirmStep
            ? 'Enter the same 4-digit M-PIN again'
            : 'Create a 4-digit M-PIN for quick access');

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
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: ValueKey(_confirmStep),
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
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? 'Please wait'
                          : (_isSetup && _confirmStep ? 'Confirm' : 'Continue'),
                    ),
                  ),
                  if (_isSetup && _confirmStep) ...[
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
