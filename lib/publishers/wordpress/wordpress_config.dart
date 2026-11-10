// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:convert';

import '../../core/storage/key_value_store.dart';

/// Why a site address was rejected by [normalizeSiteUrl].
enum SiteUrlError { empty, invalid, httpsRequired }

class SiteUrlException implements Exception {
  const SiteUrlException(this.error);

  final SiteUrlError error;

  @override
  String toString() => 'SiteUrlException(${error.name})';
}

/// Turns what the user typed into the site's base URL.
///
/// `example.com/wp-admin/` → `https://example.com`. Plain HTTP is refused
/// because WordPress disables Application Passwords without HTTPS.
Uri normalizeSiteUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) throw const SiteUrlException(SiteUrlError.empty);
  if (!text.contains('://')) text = 'https://$text';

  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty || uri.host.contains(' ')) {
    throw const SiteUrlException(SiteUrlError.invalid);
  }
  if (uri.scheme.toLowerCase() != 'https') {
    throw const SiteUrlException(SiteUrlError.httpsRequired);
  }

  var path = uri.path;
  const suffixes = ['/wp-admin', '/wp-login.php', '/wp-json'];
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  for (final suffix in suffixes) {
    final index = path.indexOf(suffix);
    if (index >= 0) {
      path = path.substring(0, index);
      break;
    }
  }
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  return Uri(
    scheme: 'https',
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: path,
  );
}

/// Connection details for one WordPress site.
class WordPressConfig {
  const WordPressConfig({
    required this.siteUrl,
    required this.username,
    required this.applicationPassword,
    this.useRestRouteParam = false,
  });

  factory WordPressConfig.fromJson(Map<String, dynamic> json) {
    return WordPressConfig(
      siteUrl: Uri.parse(json['siteUrl'] as String),
      username: json['username'] as String,
      applicationPassword: json['applicationPassword'] as String,
      useRestRouteParam: json['useRestRouteParam'] as bool? ?? false,
    );
  }

  final Uri siteUrl;
  final String username;
  final String applicationPassword;

  /// True for sites without "pretty permalinks", where `/wp-json/` is not
  /// available and the API is reached with `?rest_route=`.
  final bool useRestRouteParam;

  WordPressConfig copyWith({bool? useRestRouteParam}) {
    return WordPressConfig(
      siteUrl: siteUrl,
      username: username,
      applicationPassword: applicationPassword,
      useRestRouteParam: useRestRouteParam ?? this.useRestRouteParam,
    );
  }

  Map<String, dynamic> toJson() => {
        'siteUrl': siteUrl.toString(),
        'username': username,
        'applicationPassword': applicationPassword,
        'useRestRouteParam': useRestRouteParam,
      };
}

/// Persists the WordPress configuration in secure storage.
class WordPressConfigRepository {
  WordPressConfigRepository(this._store);

  static const String _key = 'wordpress.config';

  final KeyValueStore _store;

  Future<WordPressConfig?> load() async {
    final raw = await _store.read(_key);
    if (raw == null) return null;
    try {
      return WordPressConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> save(WordPressConfig config) =>
      _store.write(_key, jsonEncode(config.toJson()));

  Future<void> clear() => _store.delete(_key);
}
