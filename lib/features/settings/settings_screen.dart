// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Settings. Connections (WordPress, Facebook, Instagram, AI) arrive in
/// phases 1-3; for now it exposes the open source licences page.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.settingsConnections),
            subtitle: Text(l10n.comingSoon),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationLegalese: l10n.appLegalese,
            ),
          ),
        ],
      ),
    );
  }
}
