// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:snappress/core/auth/app_lock_service.dart';
import 'package:snappress/core/auth/pbkdf2.dart';
import 'package:snappress/core/storage/key_value_store.dart';

import 'helpers.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('PBKDF2-HMAC-SHA256 (RFC 7914 / reference vectors)', () {
    final password = utf8.encode('password');
    final salt = utf8.encode('salt');

    test('1 iteration', () {
      expect(
        _hex(pbkdf2HmacSha256(password, salt, 1, 32)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('2 iterations', () {
      expect(
        _hex(pbkdf2HmacSha256(password, salt, 2, 32)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('4096 iterations', () {
      expect(
        _hex(pbkdf2HmacSha256(password, salt, 4096, 32)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('output longer than one block', () {
      expect(
        _hex(
          pbkdf2HmacSha256(
            utf8.encode('passwordPASSWORDpassword'),
            utf8.encode('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
            4096,
            40,
          ),
        ),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347e'
        'bc1800181c4e2a1fb8dd53e1c635518c7dac47e9',
      );
    });
  });

  group('PasswordHasher', () {
    test('verifies the right password only', () async {
      final encoded = await testHasher.hash('segreta1');
      expect(encoded, startsWith(r'pbkdf2-sha256$1000$'));
      expect(await testHasher.verify('segreta1', encoded), isTrue);
      expect(await testHasher.verify('segreta2', encoded), isFalse);
    });

    test('uses a random salt', () async {
      expect(
        await testHasher.hash('segreta1'),
        isNot(await testHasher.hash('segreta1')),
      );
    });

    test('rejects malformed hashes', () async {
      expect(await testHasher.verify('x', 'garbage'), isFalse);
      expect(await testHasher.verify('x', r'pbkdf2-sha256$0$AA==$AA=='), isFalse);
    });
  });

  group('AppLockService', () {
    late DateTime now;
    late InMemoryKeyValueStore store;
    late FakeBiometrics biometrics;

    AppLockService create() => AppLockService(
          store: store,
          biometrics: biometrics,
          hasher: testHasher,
          clock: () => now,
        );

    setUp(() {
      now = DateTime(2026, 11, 5, 12);
      store = InMemoryKeyValueStore();
      biometrics = FakeBiometrics();
    });

    test('needs setup on first launch, locked afterwards', () async {
      final first = create();
      await first.init();
      expect(first.state, AppLockState.needsSetup);
      await first.setPassword('segreta1');
      expect(first.state, AppLockState.unlocked);

      final second = create();
      await second.init();
      expect(second.state, AppLockState.locked);
    });

    test('rejects passwords that are too short', () async {
      final lock = create();
      await lock.init();
      expect(() => lock.setPassword('123'), throwsArgumentError);
    });

    test('locks out after too many wrong attempts', () async {
      final lock = create();
      await lock.init();
      await lock.setPassword('segreta1');
      lock.lock();

      for (var i = 0; i < lock.maxAttempts - 1; i++) {
        expect(await lock.unlockWithPassword('no'), UnlockResult.wrongPassword);
      }
      expect(await lock.unlockWithPassword('no'), UnlockResult.lockedOut);
      // Even the right password is refused during the lock-out.
      expect(await lock.unlockWithPassword('segreta1'), UnlockResult.lockedOut);

      now = now.add(lock.lockoutDuration + const Duration(seconds: 1));
      expect(await lock.unlockWithPassword('segreta1'), UnlockResult.success);
    });

    test('auto-locks only after the background timeout', () async {
      final lock = create();
      await lock.init();
      await lock.setPassword('segreta1');

      lock.onPaused();
      now = now.add(const Duration(seconds: 30));
      lock.onResumed();
      expect(lock.state, AppLockState.unlocked);

      lock.onPaused();
      now = now.add(lock.autoLockAfter);
      lock.onResumed();
      expect(lock.state, AppLockState.locked);
    });

    test('biometrics unlock only when available and enabled', () async {
      final lock = create();
      await lock.init();
      await lock.setPassword('segreta1');
      lock.lock();

      expect(await lock.unlockWithBiometrics('reason'), isFalse);
      expect(biometrics.calls, 0);

      biometrics.available = true;
      final withBio = create();
      await withBio.init();
      await withBio.setBiometricsEnabled(true);
      expect(await withBio.unlockWithBiometrics('reason'), isTrue);
      expect(withBio.state, AppLockState.unlocked);
    });

    test('never stores the password in clear', () async {
      final lock = create();
      await lock.init();
      await lock.setPassword('segreta1');
      for (final key in ['lock.passwordHash', 'lock.biometricsEnabled']) {
        expect(await store.read(key) ?? '', isNot(contains('segreta1')));
      }
    });
  });
}
