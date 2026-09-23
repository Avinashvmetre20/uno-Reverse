import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class MpinStorage {
  static const _fileName = 'uno_reverse_mpin.json';

  static String _hash(String email, String pin) {
    return sha256.convert(utf8.encode('$email|$pin')).toString();
  }

  static Future<File> _file() async {
    final dir = Directory.systemTemp;
    return File(p.join(dir.path, _fileName));
  }

  static Future<Map<String, dynamic>> _read() async {
    final file = await _file();
    if (!await file.exists()) {
      return {};
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _write(Map<String, dynamic> data) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(data));
  }

  static Future<bool> hasPinFor(String email) async {
    final data = await _read();
    final savedEmail = data['email'];
    final hash = data['hash'];
    return savedEmail == email.toLowerCase() &&
        hash is String &&
        hash.isNotEmpty;
  }

  static Future<void> save(String email, String pin) async {
    await _write({
      'email': email.toLowerCase(),
      'hash': _hash(email.toLowerCase(), pin),
    });
  }

  static Future<bool> verify(String email, String pin) async {
    final data = await _read();
    final savedEmail = data['email'];
    final hash = data['hash'];

    if (savedEmail != email.toLowerCase() || hash is! String) {
      return false;
    }

    return hash == _hash(email.toLowerCase(), pin);
  }
}
