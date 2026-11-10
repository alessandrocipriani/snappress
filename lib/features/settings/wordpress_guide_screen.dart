// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// In-app version of docs/setup/wordpress.*.md.
class WordPressGuideScreen extends StatelessWidget {
  const WordPressGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final steps = [
      l10n.wpGuideStep1,
      l10n.wpGuideStep2,
      l10n.wpGuideStep3,
      l10n.wpGuideStep4,
      l10n.wpGuideStep5,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wpGuideTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Section(
              title: l10n.wpGuideRequirementsTitle,
              child: Text(l10n.wpGuideRequirements),
            ),
            _Section(
              title: l10n.wpGuideStepsTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: CircleAvatar(
                              radius: 14,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              label: l10n.wpGuideStepLabel(i + 1),
                              child: Text(steps[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              title: l10n.wpGuideTroubleshootingTitle,
              child: Text(l10n.wpGuideTroubleshooting),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
