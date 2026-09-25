import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenSecurity {
  static const _channel = MethodChannel('core/screen_security');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}

class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenSecurity.setSecure(true);
  }

  @override
  void dispose() {
    ScreenSecurity.setSecure(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
