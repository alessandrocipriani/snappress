// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'wordpress_config.dart';

/// Error returned by the WordPress REST API or by the network.
class WordPressException implements Exception {
  const WordPressException(
    this.code,
    this.message, {
    this.statusCode,
    this.isApiResponse = false,
  });

  /// WordPress error code (e.g. `rest_cannot_create`) or a local one:
  /// `network`, `timeout`, `invalid_response`, `http_<status>`.
  final String code;
  final String message;
  final int? statusCode;

  /// True when the body was a WordPress JSON error (the REST API exists).
  final bool isApiResponse;

  @override
  String toString() => 'WordPressException($code, $statusCode): $message';
}

class WordPressUser {
  const WordPressUser({
    required this.name,
    required this.canUploadFiles,
    required this.canPublishPosts,
  });

  final String name;
  final bool canUploadFiles;
  final bool canPublishPosts;
}

class WordPressMedia {
  const WordPressMedia({required this.id, required this.sourceUrl});

  final int id;
  final Uri sourceUrl;
}

class WordPressPost {
  const WordPressPost({required this.id, required this.link});

  final int id;
  final Uri? link;
}

/// Thin client for the endpoints SnapPress needs (`/wp/v2/...`).
class WordPressClient {
  WordPressClient(
    this.config, {
    required http.Client httpClient,
    this.timeout = const Duration(seconds: 60),
  }) : _http = httpClient;

  final WordPressConfig config;
  final http.Client _http;
  final Duration timeout;

  Map<String, String> get _authHeaders {
    final password = config.applicationPassword.replaceAll(' ', '');
    final token = base64Encode(utf8.encode('${config.username}:$password'));
    return {'Authorization': 'Basic $token', 'Accept': 'application/json'};
  }

  /// Builds the URL of a `/wp/v2` route, e.g. `/users/me`.
  Uri endpoint(String route, [Map<String, String>? query]) {
    final base = config.siteUrl;
    if (config.useRestRouteParam) {
      return base.replace(
        path: '${base.path}/',
        queryParameters: {'rest_route': '/wp/v2$route', ...?query},
      );
    }
    return base.replace(
      path: '${base.path}/wp-json/wp/v2$route',
      queryParameters: query,
    );
  }

  /// The logged-in user and their capabilities.
  Future<WordPressUser> currentUser() async {
    final json = await _getJson(endpoint('/users/me', {'context': 'edit'}));
    final caps = (json['capabilities'] as Map?) ?? const {};
    return WordPressUser(
      name: (json['name'] as String?) ?? config.username,
      canUploadFiles: caps['upload_files'] == true,
      canPublishPosts: caps['publish_posts'] == true,
    );
  }

  Future<WordPressMedia> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final response = await _send(
      () => _http.post(
        endpoint('/media'),
        headers: {
          ..._authHeaders,
          'Content-Type': mimeType,
          'Content-Disposition': 'attachment; filename="$safeName"',
        },
        body: bytes,
      ),
    );
    final json = _decode(response);
    final id = json['id'];
    final source = json['source_url'];
    if (id is! int || source is! String) {
      throw const WordPressException(
        'invalid_response',
        'Unexpected response when uploading the image',
      );
    }
    return WordPressMedia(id: id, sourceUrl: Uri.parse(source));
  }

  Future<void> setMediaAltText(int mediaId, String altText) async {
    await _postJson(endpoint('/media/$mediaId'), {'alt_text': altText});
  }

  Future<WordPressPost> createPost({
    required String title,
    required String content,
    required String status,
    int? featuredMediaId,
  }) async {
    final json = await _postJson(endpoint('/posts'), {
      'title': title,
      'content': content,
      'status': status,
      if (featuredMediaId != null) 'featured_media': featuredMediaId,
    });
    final id = json['id'];
    if (id is! int) {
      throw const WordPressException(
        'invalid_response',
        'Unexpected response when creating the post',
      );
    }
    final link = json['link'];
    return WordPressPost(id: id, link: link is String ? Uri.parse(link) : null);
  }

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    final response = await _send(() => _http.get(url, headers: _authHeaders));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri url,
    Map<String, dynamic> body,
  ) async {
    final response = await _send(
      () => _http.post(
        url,
        headers: {
          ..._authHeaders,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const WordPressException('timeout', 'The site did not respond');
    } on http.ClientException catch (e) {
      throw WordPressException('network', e.message);
    } on Exception catch (e) {
      // e.g. TLS handshake errors on some platforms.
      throw WordPressException('network', e.toString());
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && json is Map<String, dynamic>) return json;

    if (json is Map<String, dynamic> && json['code'] is String) {
      throw WordPressException(
        json['code'] as String,
        (json['message'] as String?) ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        isApiResponse: true,
      );
    }
    throw WordPressException(
      ok ? 'invalid_response' : 'http_${response.statusCode}',
      ok
          ? 'The site did not return valid JSON'
          : 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}

/// Result of [checkWordPressConnection].
class WordPressConnectionCheck {
  const WordPressConnectionCheck({required this.config, required this.user});

  /// Possibly updated (e.g. `useRestRouteParam`): save this one.
  final WordPressConfig config;
  final WordPressUser user;
}

/// Verifies credentials, falling back to `?rest_route=` on sites without
/// pretty permalinks.
Future<WordPressConnectionCheck> checkWordPressConnection(
  WordPressConfig config,
  http.Client httpClient,
) async {
  try {
    final user = await WordPressClient(config, httpClient: httpClient)
        .currentUser();
    return WordPressConnectionCheck(config: config, user: user);
  } on WordPressException catch (e) {
    final apiMissing = !e.isApiResponse &&
        (e.statusCode == 404 || e.code == 'invalid_response');
    if (!apiMissing || config.useRestRouteParam) rethrow;

    final fallback = config.copyWith(useRestRouteParam: true);
    final user = await WordPressClient(fallback, httpClient: httpClient)
        .currentUser();
    return WordPressConnectionCheck(config: fallback, user: user);
  }
}
