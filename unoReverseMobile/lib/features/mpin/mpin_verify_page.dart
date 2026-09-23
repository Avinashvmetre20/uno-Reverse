import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/storage/mpin_storage.dart';
import 'package:uno_reverse/features/home/home_page.dart';

class MpinVerifyPage extends StatefulWidget {
  const MpinVerifyPage({super.key, required this.email});

  final String email;

  @override
  State<MpinVerifyPage> createState() => _MpinVerifyPageState();
}

class _MpinVerifyPageState extends State<MpinVerifyPage> {
  final _pin = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_pin.text.length != 4) {
      setState(() => _error = 'Enter your 4-digit M-PIN');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Enter M-PIN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock Uno Reverse',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() => _error = null);
                      }
                    },
                    onSubmitted: (_) => _verify(),
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
                    onPressed: _loading ? null : _verify,
                    child: Text(_loading ? 'Please wait' : 'Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
