import 'package:flutter/foundation.dart';

class AuthLog {
  static void event(String name) {
    debugPrint(name);
  }
}
