import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class ParentPinCredentials {
  const ParentPinCredentials({required this.hash, required this.salt});

  final String hash;
  final String salt;
}

class ParentPinSecurity {
  const ParentPinSecurity._();

  static ParentPinCredentials createCredentials(String pin) {
    final salt = _generateSalt();
    return ParentPinCredentials(hash: _hash(pin, salt), salt: salt);
  }

  static bool verify({
    required String pin,
    required String? hash,
    required String? salt,
  }) {
    if (hash == null || hash.isEmpty || salt == null || salt.isEmpty) {
      return false;
    }

    return _constantTimeEquals(_hash(pin, salt), hash);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index += 1) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }

    return result == 0;
  }
}
