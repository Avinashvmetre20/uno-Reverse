import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/core/authentication/mpin_store.dart';
import 'package:uno_reverse/core/security/screen_security.dart';

class MpinChangePage extends StatefulWidget {
  const MpinChangePage({super.key});

  @override
  State<MpinChangePage> createState() => _MpinChangePageState();
}

class _MpinChangePageState extends State<MpinChangePage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).changePin(
        current: _current.text,
        next: _next.text,
        confirm: _confirm.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
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
        appBar: AppBar(title: const Text('Change M-PIN')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _field(_current, 'Current M-PIN'),
              const SizedBox(height: 16),
              _field(_next, 'New M-PIN'),
              const SizedBox(height: 16),
              _field(_confirm, 'Confirm M-PIN'),
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
                child: Text(_loading ? 'Please wait' : 'Update M-PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }
}
