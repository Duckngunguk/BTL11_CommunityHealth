import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class PasswordHasher {
  static const _prefix = 'sha256:';

  static String hash(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return '$_prefix$digest';
  }

  static bool verify(String password, String storedHash) {
    if (storedHash.startsWith(_prefix)) {
      return hash(password) == storedHash;
    }
    return password == storedHash;
  }
}
