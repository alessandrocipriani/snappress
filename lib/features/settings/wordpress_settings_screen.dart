// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../l10n/app_localizations.dart';
import '../../publishers/wordpress/wordpress_client.dart';
import '../../publishers/wordpress/wordpress_config.dart';
import 'wordpress_guide_screen.dart';

/// Form to connect a WordPress site, with "test and save".
class WordPressSettingsScreen extends StatefulWidget {
  const WordPressSettingsScreen({super.key});

  @override
  State<WordPressSettingsScreen> createState() =>
      _WordPressSettingsScreenState();
}

enum _StatusKind { info, success, error }

class _WordPressSettingsScreenState extends State<WordPressSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrl = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  bool _configured = false;
  bool _obscurePassword = true;
  String? _status;
  _StatusKind _statusKind = _StatusKind.info;

  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    final config = await AppScope.of(context).wordpressConfig.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (config != null) {
        _configured = true;
        _siteUrl.text = config.siteUrl.toString();
        _username.text = config.username;
        _password.text = config.applicationPassword;
      }
    });
  }

  @override
  void dispose() {
    _siteUrl.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value, AppLocalizations l10n) {
    try {
      normalizeSiteUrl(value ?? '');
      return null;
    } on SiteUrlException catch (e) {
      return switch (e.error) {
        SiteUrlError.empty => l10n.fieldRequired,
        SiteUrlError.invalid => l10n.wpErrorInvalidUrl,
        SiteUrlError.httpsRequired => l10n.wpErrorHttpsRequired,
      };
    }
  }

  Future<void> _testAndSave() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final services = AppScope.of(context);

    setState(() {
      _busy = true;
      _status = l10n.wpTesting;
      _statusKind = _StatusKind.info;
    });

    final config = WordPressConfig(
      siteUrl: normalizeSiteUrl(_siteUrl.text),
      username: _username.text.trim(),
      applicationPassword: _password.text.trim(),
    );

    String message;
    var kind = _StatusKind.error;
    WordPressConfig? saved;
    try {
      final check =
          await checkWordPressConnection(config, services.httpClient);
      if (!check.user.canUploadFiles) {
        message = l10n.wpErrorRole;
      } else {
        await services.wordpressConfig.save(check.config);
        saved = check.config;
        message = l10n.wpConnected(check.user.name);
        kind = _StatusKind.success;
      }
    } on WordPressException catch (e) {
      message = _describeError(e, l10n);
    }

    if (!mounted) return;
    final savedConfig = saved;
    setState(() {
      _busy = false;
      _status = message;
      _statusKind = kind;
      if (savedConfig != null) {
        _configured = true;
        _siteUrl.text = savedConfig.siteUrl.toString();
      }
    });
  }

  String _describeError(WordPressException e, AppLocalizations l10n) {
    if (e.code == 'network' || e.code == 'timeout') return l10n.wpErrorNetwork;
    if (e.statusCode == 401) return l10n.wpErrorCredentials;
    if (e.statusCode == 403) return l10n.wpErrorForbidden;
    if (e.statusCode == 404 || e.code == 'invalid_response') {
      return l10n.wpErrorNoApi;
    }
    return l10n.wpErrorGeneric(e.message);
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wpRemoveTitle),
        content: Text(l10n.wpRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AppScope.of(context).wordpressConfig.clear();
    if (!mounted) return;
    setState(() {
      _configured = false;
      _siteUrl.clear();
      _username.clear();
      _password.clear();
      _status = l10n.wpRemoved;
      _statusKind = _StatusKind.info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordPress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.wpGuideTitle,
            onPressed: _openGuide,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(l10n.wpIntro),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(l10n.wpOpenGuide),
                          onPressed: _openGuide,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _siteUrl,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.url],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.wpSiteUrl,
                          hintText: 'https://example.com',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => _validateUrl(v, l10n),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.wpUsername,
                          helperText: l10n.wpUsernameHelper,
                          helperMaxLines: 2,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _testAndSave(),
                        decoration: InputDecoration(
                          labelText: l10n.wpAppPassword,
                          helperText: l10n.wpAppPasswordHelper,
                          helperMaxLines: 3,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            tooltip: _obscurePassword
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.wifi_tethering),
                        label: Text(l10n.wpTestAndSave),
                        onPressed: _busy ? null : _testAndSave,
                      ),
                      if (_configured) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.wpRemove),
                          onPressed: _busy ? null : _remove,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_status != null)
                        // liveRegion: screen readers announce the result.
                        Semantics(
                          liveRegion: true,
                          child: Card(
                            color: switch (_statusKind) {
                              _StatusKind.success => colors.primaryContainer,
                              _StatusKind.error => colors.errorContainer,
                              _StatusKind.info =>
                                colors.surfaceContainerHighest,
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (_busy)
                                    const Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        end: 16,
                                      ),
                                      child: SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _status!,
                                      style: TextStyle(
                                        color: switch (_statusKind) {
                                          _StatusKind.success =>
                                            colors.onPrimaryContainer,
                                          _StatusKind.error =>
                                            colors.onErrorContainer,
                                          _StatusKind.info => colors.onSurface,
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WordPressGuideScreen()),
    );
  }
}
