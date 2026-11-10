// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snappress/core/app_services.dart';
import 'package:snappress/core/auth/app_lock_service.dart';
import 'package:snappress/core/auth/biometric_authenticator.dart';
import 'package:snappress/core/auth/password_hasher.dart';
import 'package:snappress/core/storage/key_value_store.dart';

/// Fast, synchronous hasher for tests.
const testHasher = PasswordHasher(iterations: 1000, useIsolate: false);

class FakeBiometrics implements BiometricAuthenticator {
  FakeBiometrics({this.available = false, this.succeeds = true});

  bool available;
  bool succeeds;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String localizedReason) async {
    calls++;
    return succeeds;
  }
}

/// Services backed by memory. [password] creates an existing lock;
/// [unlocked] additionally unlocks it.
Future<AppServices> createTestServices({
  String? password,
  bool unlocked = false,
  FakeBiometrics? biometrics,
  http.Client? httpClient,
}) async {
  final store = InMemoryKeyValueStore();
  final lock = AppLockService(
    store: store,
    biometrics: biometrics ?? FakeBiometrics(),
    hasher: testHasher,
  );
  if (password != null) {
    await lock.setPassword(password);
  }
  await lock.init();
  if (password != null && unlocked) {
    await lock.unlockWithPassword(password);
  }
  return AppServices(
    store: store,
    lock: lock,
    httpClient:
        httpClient ?? MockClient((_) async => http.Response('{}', 404)),
  );
}
