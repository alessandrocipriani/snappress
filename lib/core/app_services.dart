// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../publishers/wordpress/wordpress_config.dart';
import 'auth/app_lock_service.dart';
import 'auth/biometric_authenticator.dart';
import 'storage/key_value_store.dart';

/// Long-lived services shared by the whole app.
class AppServices {
  AppServices({
    required this.store,
    required this.lock,
    required this.httpClient,
  }) : wordpressConfig = WordPressConfigRepository(store);

  final KeyValueStore store;
  final AppLockService lock;
  final http.Client httpClient;
  final WordPressConfigRepository wordpressConfig;

  static const String _installedFlag = 'snappress.installed';

  /// Production wiring.
  static Future<AppServices> create() async {
    const store = SecureKeyValueStore();
    await _clearKeychainAfterReinstall(store);

    final lock = AppLockService(
      store: store,
      biometrics: LocalAuthBiometricAuthenticator(),
    );
    await lock.init();

    return AppServices(store: store, lock: lock, httpClient: http.Client());
  }

  /// On iOS the Keychain survives uninstalling the app. A flag in normal
  /// preferences (which are removed on uninstall) tells us whether this is a
  /// fresh install, in which case old credentials are wiped.
  static Future<void> _clearKeychainAfterReinstall(KeyValueStore store) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installedFlag) != true) {
      await store.deleteAll();
      await prefs.setBool(_installedFlag, true);
    }
  }
}

/// Makes [AppServices] available to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services;
}
