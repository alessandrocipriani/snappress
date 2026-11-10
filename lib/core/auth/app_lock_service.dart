// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';
import 'biometric_authenticator.dart';
import 'password_hasher.dart';

enum AppLockState { loading, needsSetup, locked, unlocked }

enum UnlockResult { success, wrongPassword, lockedOut }

/// Controls access to the app: password (always) plus optional biometrics,
/// a temporary lock-out after repeated failures, and auto-lock when the app
/// stays in background.
class AppLockService extends ChangeNotifier {
  AppLockService({
    required KeyValueStore store,
    required BiometricAuthenticator biometrics,
    PasswordHasher hasher = const PasswordHasher(),
    this.autoLockAfter = const Duration(minutes: 2),
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _store = store,
        _biometrics = biometrics,
        _hasher = hasher,
        _clock = clock ?? DateTime.now;

  static const int minPasswordLength = 6;
  static const String _hashKey = 'lock.passwordHash';
  static const String _biometricsKey = 'lock.biometricsEnabled';

  final KeyValueStore _store;
  final BiometricAuthenticator _biometrics;
  final PasswordHasher _hasher;
  final DateTime Function() _clock;

  /// Time in background after which the app locks again.
  final Duration autoLockAfter;
  final int maxAttempts;
  final Duration lockoutDuration;

  AppLockState _state = AppLockState.loading;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  int _failedAttempts = 0;
  DateTime? _lockedOutUntil;
  DateTime? _pausedAt;

  AppLockState get state => _state;

  bool get biometricsAvailable => _biometricsAvailable;

  bool get biometricsEnabled => _biometricsEnabled;

  bool get canUseBiometrics => _biometricsEnabled && _biometricsAvailable;

  /// Remaining lock-out time, or null if the user may try again.
  Duration? get lockoutRemaining {
    final until = _lockedOutUntil;
    if (until == null) return null;
    final remaining = until.difference(_clock());
    return remaining.isNegative ? null : remaining;
  }

  Future<void> init() async {
    final hash = await _store.read(_hashKey);
    _biometricsEnabled = await _store.read(_biometricsKey) == 'true';
    _biometricsAvailable = await _biometrics.isAvailable();
    _state = hash == null ? AppLockState.needsSetup : AppLockState.locked;
    notifyListeners();
  }

  /// Sets (or replaces) the app password and unlocks the app.
  Future<void> setPassword(String password) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError('Password shorter than $minPasswordLength');
    }
    await _store.write(_hashKey, await _hasher.hash(password));
    _resetFailures();
    _state = AppLockState.unlocked;
    notifyListeners();
  }

  Future<UnlockResult> unlockWithPassword(String password) async {
    if (lockoutRemaining != null) return UnlockResult.lockedOut;

    final stored = await _store.read(_hashKey);
    if (stored != null && await _hasher.verify(password, stored)) {
      _resetFailures();
      _state = AppLockState.unlocked;
      notifyListeners();
      return UnlockResult.success;
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _failedAttempts = 0;
      _lockedOutUntil = _clock().add(lockoutDuration);
      notifyListeners();
      return UnlockResult.lockedOut;
    }
    notifyListeners();
    return UnlockResult.wrongPassword;
  }

  Future<bool> unlockWithBiometrics(String localizedReason) async {
    if (!canUseBiometrics) return false;
    final ok = await _biometrics.authenticate(localizedReason);
    if (ok) {
      _resetFailures();
      _state = AppLockState.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    _biometricsEnabled = enabled && _biometricsAvailable;
    await _store.write(_biometricsKey, _biometricsEnabled.toString());
    notifyListeners();
  }

  void lock() {
    if (_state != AppLockState.unlocked) return;
    _state = AppLockState.locked;
    notifyListeners();
  }

  /// Call when the app goes to background.
  void onPaused() => _pausedAt = _clock();

  /// Call when the app returns to foreground.
  void onResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null && _clock().difference(pausedAt) >= autoLockAfter) {
      lock();
    }
  }

  void _resetFailures() {
    _failedAttempts = 0;
    _lockedOutUntil = null;
  }
}
