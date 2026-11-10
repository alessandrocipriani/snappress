// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2 with HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2HmacSha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int length,
) {
  if (iterations < 1) throw ArgumentError.value(iterations, 'iterations');
  if (length < 1) throw ArgumentError.value(length, 'length');

  final hmac = Hmac(sha256, password);
  const blockSize = 32;
  final blockCount = (length + blockSize - 1) ~/ blockSize;
  final output = BytesBuilder(copy: false);

  for (var block = 1; block <= blockCount; block++) {
    final blockIndex = Uint8List(4)
      ..buffer.asByteData().setUint32(0, block, Endian.big);
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    output.add(t);
  }

  return Uint8List.sublistView(output.takeBytes(), 0, length);
}

/// Compares two byte lists in time independent of where they differ.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
