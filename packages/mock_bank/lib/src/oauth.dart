import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The user the bank is provisioned with.
typedef DemoUser = ({
  String username,
  String password,
  String name,
  String companyName,
});

/// A stored password: salted SHA-256, never the password itself.
final class StoredCredential {
  StoredCredential._(this._salt, this._hash);

  factory StoredCredential.create({
    required String password,
    required Random random,
  }) {
    final salt = randomUrlSafe(16, random);
    return StoredCredential._(salt, _digest(salt, password));
  }

  final String _salt;
  final String _hash;

  bool matches(String password) {
    final candidate = _digest(_salt, password);
    // Constant-time comparison, so response timing leaks nothing.
    if (candidate.length != _hash.length) return false;
    var difference = 0;
    for (var i = 0; i < candidate.length; i++) {
      difference |= candidate.codeUnitAt(i) ^ _hash.codeUnitAt(i);
    }
    return difference == 0;
  }

  static String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}

/// [bytes] of randomness from [random], base64url without padding.
String randomUrlSafe(int bytes, Random random) => base64Url
    .encode(List<int>.generate(bytes, (_) => random.nextInt(256)))
    .replaceAll('=', '');
