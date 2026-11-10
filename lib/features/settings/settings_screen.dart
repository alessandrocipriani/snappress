// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../l10n/app_localizations.dart';
import 'wordpress_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lock = AppScope.of(context).lock;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListView(
          children: [
            _Header(l10n.settingsConnections),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('WordPress'),
              subtitle: Text(l10n.settingsWordPressSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WordPressSettingsScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Facebook · Instagram'),
              subtitle: Text(l10n.comingSoon),
              enabled: false,
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.settingsAi),
              subtitle: Text(l10n.comingSoon),
              enabled: false,
            ),
            const Divider(),
            _Header(l10n.settingsSecurity),
            if (lock.biometricsAvailable)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(l10n.lockUseBiometrics),
                value: lock.biometricsEnabled,
                onChanged: lock.setBiometricsEnabled,
              ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsLockNow),
              onTap: lock.lock,
            ),
            const Divider(),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
