import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uno_reverse/core/authentication/auth_policy.dart';
import 'package:uno_reverse/core/security/secure_store.dart';

class MpinKeys {
  static const user = 'auth.pin_user';
  static const salt = 'auth.pin_salt';
  static const hash = 'auth.pin_hash';
  static const attempts = 'auth.pin_attempts';
  static const lockedUntil = 'auth.pin_locked_until';
  static const biometric = 'auth.biometric_enabled';
}

class MpinException implements Exception {
  MpinException(this.message);

  final String message;
}

class MpinStore {
  MpinStore(this._store, {DateTime Function()? clock, Random? random})
      : _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure();

  final SecureStore _store;
  final DateTime Function() _clock;
  final Random _random;

  Future<bool> isConfiguredFor(String email) async {
    final savedUser = await _store.read(MpinKeys.user);
    final hash = await _store.read(MpinKeys.hash);
    return savedUser == email.toLowerCase() && hash != null && hash.isNotEmpty;
  }

  Future<bool> biometricEnabled() async {
    return await _store.read(MpinKeys.biometric) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) {
    return _store.write(MpinKeys.biometric, enabled ? 'true' : 'false');
  }

  Future<Duration?> lockRemaining() async {
    final raw = await _store.read(MpinKeys.lockedUntil);
    if (raw == null) {
      return null;
    }
    final until = DateTime.tryParse(raw);
    if (until == null) {
      return null;
    }
    final remaining = until.difference(_clock());
    if (remaining <= Duration.zero) {
      await _store.delete(MpinKeys.lockedUntil);
      await _store.write(MpinKeys.attempts, '0');
      return null;
    }
    return remaining;
  }

  Future<void> setup(String email, String pin, String confirm) async {
    _validateNewPin(pin, confirm);
    await _writePin(email, pin);
  }

  Future<void> verify(String email, String pin) async {
    await _ensureUnlocked();
    final ok = await _matches(email, pin);
    if (!ok) {
      await _recordFailure();
      throw MpinException('Incorrect M-PIN');
    }
    await _store.write(MpinKeys.attempts, '0');
    await _store.delete(MpinKeys.lockedUntil);
  }

  Future<void> change({
    required String email,
    required String current,
    required String next,
    required String confirm,
  }) async {
    await verify(email, current);
    _validateNewPin(next, confirm);
    await _writePin(email, next);
  }

  Future<void> clear() async {
    await _store.delete(MpinKeys.user);
    await _store.delete(MpinKeys.salt);
    await _store.delete(MpinKeys.hash);
    await _store.delete(MpinKeys.attempts);
    await _store.delete(MpinKeys.lockedUntil);
    await _store.delete(MpinKeys.biometric);
  }

  void _validateNewPin(String pin, String confirm) {
    if (!_isFourDigits(pin) || !_isFourDigits(confirm)) {
      throw MpinException('Enter a 4-digit M-PIN');
    }
    if (pin != confirm) {
      throw MpinException('M-PIN does not match');
    }
    if (AuthPolicy.trivialPins.contains(pin)) {
      throw MpinException('Choose a less obvious M-PIN');
    }
  }

  bool _isFourDigits(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  Future<void> _writePin(String email, String pin) async {
    final salt = _salt();
    await _store.write(MpinKeys.user, email.toLowerCase());
    await _store.write(MpinKeys.salt, salt);
    await _store.write(MpinKeys.hash, _hash(salt, pin));
    await _store.write(MpinKeys.attempts, '0');
    await _store.delete(MpinKeys.lockedUntil);
  }

  Future<bool> _matches(String email, String pin) async {
    if (!await isConfiguredFor(email)) {
      return false;
    }
    final salt = await _store.read(MpinKeys.salt);
    final hash = await _store.read(MpinKeys.hash);
    if (salt == null || hash == null) {
      return false;
    }
    return hash == _hash(salt, pin);
  }

  Future<void> _ensureUnlocked() async {
    final remaining = await lockRemaining();
    if (remaining != null) {
      throw MpinException('Too many attempts. Try again in a minute.');
    }
  }

  Future<void> _recordFailure() async {
    final raw = await _store.read(MpinKeys.attempts);
    final attempts = (int.tryParse(raw ?? '') ?? 0) + 1;
    await _store.write(MpinKeys.attempts, '$attempts');
    if (attempts >= AuthPolicy.maxPinAttempts) {
      final until = _clock().add(AuthPolicy.pinLockout);
      await _store.write(MpinKeys.lockedUntil, until.toIso8601String());
    }
  }

  String _salt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt|$pin')).toString();
  }
}
