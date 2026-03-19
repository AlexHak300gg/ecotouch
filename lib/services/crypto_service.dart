import 'package:crypto/crypto.dart';
import 'dart:convert';

class CryptoService {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  static String generateToken() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode(random.toString());
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
