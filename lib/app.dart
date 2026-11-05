// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

/// Root widget of SnapPress.
class SnapPressApp extends StatelessWidget {
  const SnapPressApp({super.key, this.locale});

  /// Forces a language. When null, the device language is used
  /// (falling back to English if it is not supported).
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
