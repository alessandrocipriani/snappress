// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_services.dart';
import '../../l10n/app_localizations.dart';
import '../../publishers/publisher.dart';
import '../../publishers/wordpress/wordpress_client.dart';
import '../../publishers/wordpress/wordpress_config.dart';
import '../../publishers/wordpress/wordpress_publisher.dart';
import '../settings/wordpress_settings_screen.dart';

/// Pick an image, write the texts, publish.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.imagePicker});

  /// Injectable for tests.
  final ImagePicker? imagePicker;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _altText = TextEditingController();
  final _hashtags = TextEditingController();

  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  WordPressConfig? _wordpress;
  bool _configLoaded = false;
  bool _loadStarted = false;
  bool _publishNow = false;
  bool _publishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _loadConfig();
    }
  }

  Future<void> _loadConfig() async {
    final config = await AppScope.of(context).wordpressConfig.load();
    if (!mounted) return;
    setState(() {
      _wordpress = config;
      _configLoaded = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _altText.dispose();
    _hashtags.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _picker.pickImage(
        source: source,
        // Re-encoding keeps uploads small and strips most metadata.
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.composePickError)));
    }
  }

  List<String> _parseHashtags() => _hashtags.text
      .split(RegExp(r'[\s,]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty && t != '#')
      .toList();

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final config = _wordpress;
    final bytes = _imageBytes;
    if (config == null || bytes == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _publishing = true);
    final services = AppScope.of(context);
    final publisher = WordPressPublisher(
      WordPressClient(config, httpClient: services.httpClient),
    );
    final result = await publisher.publish(
      PostDraft(
        imageBytes: bytes,
        imageFileName: _imageName ?? 'image.jpg',
        title: _title.text,
        body: _body.text,
        altText: _altText.text,
        hashtags: _parseHashtags(),
        asDraft: !_publishNow,
      ),
    );
    if (!mounted) return;
    setState(() => _publishing = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
        ),
        title: Text(
          result.isSuccess
              ? (_publishNow ? l10n.composePublished : l10n.composeDraftSaved)
              : l10n.composePublishFailed,
        ),
        content: result.isSuccess
            ? (result.url == null
                ? null
                : SelectableText(result.url.toString()))
            : Text(result.errorMessage ?? ''),
        actions: [
          if (result.isSuccess && result.url != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.url.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.linkCopied)),
                );
              },
              child: Text(l10n.copyLink),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _openWordPressSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WordPressSettingsScreen(),
      ),
    );
    if (mounted) await _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPublish =
        _imageBytes != null && _wordpress != null && !_publishing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPost)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ImageSection(
                bytes: _imageBytes,
                altText: _altText.text,
                onGallery: () => _pick(ImageSource.gallery),
                onCamera: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _altText,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.composeAltText,
                  helperText: l10n.composeAltTextHelper,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.composeTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _body,
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.composeBody,
                  helperText: l10n.composeBodyHelper,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hashtags,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.composeHashtags,
                  hintText: '#travel #food',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.composeDestinations,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!_configLoaded)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_wordpress == null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.composeWordPressMissing),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openWordPressSettings,
                  ),
                )
              else ...[
                CheckboxListTile(
                  value: true,
                  onChanged: null,
                  title: const Text('WordPress'),
                  subtitle: Text(_wordpress!.siteUrl.host),
                  secondary: const Icon(Icons.public),
                ),
                SwitchListTile(
                  value: _publishNow,
                  onChanged: _publishing
                      ? null
                      : (v) => setState(() => _publishNow = v),
                  title: Text(l10n.composePublishNow),
                  subtitle: Text(
                    _publishNow
                        ? l10n.composePublishNowOn
                        : l10n.composePublishNowOff,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: canPublish ? _publish : null,
                icon: _publishing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _publishing
                      ? l10n.composePublishing
                      : (_publishNow
                          ? l10n.composePublishButton
                          : l10n.composeSaveDraftButton),
                ),
              ),
              if (_imageBytes == null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.composeNeedImage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.bytes,
    required this.altText,
    required this.onGallery,
    required this.onCamera,
  });

  final Uint8List? bytes;
  final String altText;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final image = bytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 240,
            color: colors.surfaceContainerHighest,
            alignment: Alignment.center,
            child: image == null
                ? Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: colors.onSurfaceVariant,
                    semanticLabel: l10n.composeNoImage,
                  )
                : Image.memory(
                    image,
                    fit: BoxFit.contain,
                    semanticLabel: altText.trim().isEmpty
                        ? l10n.composeSelectedImage
                        : altText,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.composeFromGallery),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.composeFromCamera),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
