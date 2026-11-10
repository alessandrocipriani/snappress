// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'pbkdf2.dart';

/// Hashes the app password with PBKDF2-HMAC-SHA256 and a random salt.
///
/// Encoded format: `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`.
/// The password itself is never stored.
class PasswordHasher {
  const PasswordHasher({this.iterations = 210000, this.useIsolate = true});

  /// OWASP 2023 recommendation for PBKDF2-HMAC-SHA256.
  final int iterations;

  /// Runs the (slow) derivation off the UI thread. Disable in tests.
  final bool useIsolate;

  static const String _scheme = 'pbkdf2-sha256';

  Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final derived = await _derive(password, salt, iterations, 32);
    return '$_scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final storedIterations = int.tryParse(parts[1]);
    if (storedIterations == null || storedIterations < 1) return false;
    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final derived =
          await _derive(password, salt, storedIterations, expected.length);
      return constantTimeEquals(derived, expected);
    } on FormatException {
      return false;
    }
  }

  Future<Uint8List> _derive(
    String password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final passwordBytes = utf8.encode(password);
    if (!useIsolate) {
      return Future.value(
        pbkdf2HmacSha256(passwordBytes, salt, iterations, length),
      );
    }
    return Isolate.run(
      () => pbkdf2HmacSha256(passwordBytes, salt, iterations, length),
    );
  }
}
