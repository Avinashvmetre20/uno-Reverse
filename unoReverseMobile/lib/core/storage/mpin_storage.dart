import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MpinStorage {
  static const _emailKey = 'mpin_email';
  static const _hashKey = 'mpin_hash';

  static String _hash(String email, String pin) {
    return sha256.convert(utf8.encode('$email|$pin')).toString();
  }

  static Future<bool> hasPinFor(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final hash = prefs.getString(_hashKey);
    return savedEmail == email.toLowerCase() && hash != null && hash.isNotEmpty;
  }

  static Future<void> save(String email, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.toLowerCase());
    await prefs.setString(_hashKey, _hash(email.toLowerCase(), pin));
  }

  static Future<bool> verify(String email, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final hash = prefs.getString(_hashKey);

    if (savedEmail != email.toLowerCase() || hash == null) {
      return false;
    }

    return hash == _hash(email.toLowerCase(), pin);
  }
}
