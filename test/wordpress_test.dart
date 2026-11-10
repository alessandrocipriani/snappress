// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snappress/core/storage/key_value_store.dart';
import 'package:snappress/publishers/publisher.dart';
import 'package:snappress/publishers/wordpress/wordpress_client.dart';
import 'package:snappress/publishers/wordpress/wordpress_config.dart';
import 'package:snappress/publishers/wordpress/wordpress_content.dart';
import 'package:snappress/publishers/wordpress/wordpress_publisher.dart';

final _config = WordPressConfig(
  siteUrl: Uri.parse('https://example.com/blog'),
  username: 'mario',
  applicationPassword: 'abcd efgh ijkl mnop',
);

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('normalizeSiteUrl', () {
    test('adds https and removes admin paths and slashes', () {
      expect(normalizeSiteUrl('Example.com').toString(), 'https://example.com');
      expect(
        normalizeSiteUrl(' https://example.com/wp-admin/ ').toString(),
        'https://example.com',
      );
      expect(
        normalizeSiteUrl('example.com/blog/wp-login.php').toString(),
        'https://example.com/blog',
      );
      expect(
        normalizeSiteUrl('https://example.com:8443/').toString(),
        'https://example.com:8443',
      );
    });

    test('refuses empty, invalid and plain http addresses', () {
      Matcher error(SiteUrlError e) => throwsA(
            isA<SiteUrlException>().having((x) => x.error, 'error', e),
          );
      expect(() => normalizeSiteUrl('  '), error(SiteUrlError.empty));
      expect(
        () => normalizeSiteUrl('http://example.com'),
        error(SiteUrlError.httpsRequired),
      );
      expect(() => normalizeSiteUrl('https://'), error(SiteUrlError.invalid));
    });
  });

  group('WordPressConfigRepository', () {
    test('round-trips the configuration', () async {
      final repo = WordPressConfigRepository(InMemoryKeyValueStore());
      expect(await repo.load(), isNull);
      await repo.save(_config.copyWith(useRestRouteParam: true));
      final loaded = await repo.load();
      expect(loaded?.siteUrl, _config.siteUrl);
      expect(loaded?.username, 'mario');
      expect(loaded?.useRestRouteParam, isTrue);
      await repo.clear();
      expect(await repo.load(), isNull);
    });
  });

  group('WordPressClient', () {
    test('builds endpoints for both URL styles', () {
      final client = WordPressClient(_config, httpClient: MockClient((_) async => _json({})));
      expect(
        client.endpoint('/posts').toString(),
        'https://example.com/blog/wp-json/wp/v2/posts',
      );
      final plain = WordPressClient(
        _config.copyWith(useRestRouteParam: true),
        httpClient: MockClient((_) async => _json({})),
      );
      final uri = plain.endpoint('/users/me', {'context': 'edit'});
      expect(uri.path, '/blog/');
      expect(uri.queryParameters['rest_route'], '/wp/v2/users/me');
      expect(uri.queryParameters['context'], 'edit');
    });

    test('sends Basic auth without spaces in the password', () async {
      late http.Request captured;
      final client = WordPressClient(
        _config,
        httpClient: MockClient((request) async {
          captured = request;
          return _json({
            'name': 'Mario',
            'capabilities': {'upload_files': true, 'publish_posts': true},
          });
        }),
      );
      final user = await client.currentUser();
      expect(user.name, 'Mario');
      expect(user.canUploadFiles, isTrue);
      expect(
        captured.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('mario:abcdefghijklmnop'))}',
      );
    });

    test('maps WordPress JSON errors', () async {
      final client = WordPressClient(
        _config,
        httpClient: MockClient(
          (_) async => _json(
            {'code': 'rest_cannot_create', 'message': 'Not allowed'},
            403,
          ),
        ),
      );
      expect(
        client.currentUser,
        throwsA(
          isA<WordPressException>()
              .having((e) => e.code, 'code', 'rest_cannot_create')
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.isApiResponse, 'api', isTrue),
        ),
      );
    });

    test('connection check falls back to ?rest_route=', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/wp-json/')) {
          return http.Response('<html>Not found</html>', 404);
        }
        return _json({
          'name': 'Mario',
          'capabilities': {'upload_files': true},
        });
      });
      final check = await checkWordPressConnection(_config, client);
      expect(check.config.useRestRouteParam, isTrue);
      expect(check.user.canUploadFiles, isTrue);
    });

    test('connection check does not hide wrong credentials', () async {
      final client = MockClient(
        (_) async => _json(
          {'code': 'incorrect_password', 'message': 'Wrong'},
          401,
        ),
      );
      expect(
        () => checkWordPressConnection(_config, client),
        throwsA(isA<WordPressException>()),
      );
    });
  });

  group('WordPressPublisher', () {
    test('uploads image, sets alt text and creates the post', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/media')) {
          return _json({
            'id': 42,
            'source_url': 'https://example.com/blog/wp-content/uploads/a.jpg',
          }, 201);
        }
        if (path.endsWith('/media/42')) return _json({'id': 42});
        if (path.endsWith('/posts')) {
          return _json({'id': 7, 'link': 'https://example.com/blog/?p=7'}, 201);
        }
        return http.Response('unexpected', 500);
      });

      final publisher =
          WordPressPublisher(WordPressClient(_config, httpClient: client));
      final result = await publisher.publish(
        PostDraft(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          imageFileName: 'my photo.JPG',
          title: 'Ciao',
          body: 'Primo paragrafo\n\nSecondo',
          altText: 'Un gatto sul divano',
          hashtags: const ['gatti', '#divano'],
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.url.toString(), 'https://example.com/blog/?p=7');
      expect(publisher.lastImageUrl?.path, '/blog/wp-content/uploads/a.jpg');
      expect(requests, hasLength(3));

      final upload = requests[0];
      expect(upload.headers['Content-Type'], 'image/jpeg');
      expect(upload.headers['Content-Disposition'], contains('my_photo.JPG'));
      expect(upload.bodyBytes, [1, 2, 3]);

      expect(jsonDecode(requests[1].body), {'alt_text': 'Un gatto sul divano'});

      final post = jsonDecode(requests[2].body) as Map<String, dynamic>;
      expect(post['status'], 'draft');
      expect(post['featured_media'], 42);
      expect(post['content'], contains('#gatti #divano'));
    });

    test('returns a failure instead of throwing', () async {
      final client = MockClient(
        (_) async => _json({'code': 'rest_upload_no_data', 'message': 'No data'}, 400),
      );
      final result =
          await WordPressPublisher(WordPressClient(_config, httpClient: client))
              .publish(
        PostDraft(
          imageBytes: Uint8List(0),
          imageFileName: 'a.png',
          body: 'x',
        ),
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'No data');
    });
  });

  group('buildWordPressContent', () {
    test('escapes user text and splits paragraphs', () {
      final html = buildWordPressContent(
        body: 'Uno <b>\nriga due\n\nDue & "tre"',
        mediaId: 5,
        imageUrl: Uri.parse('https://example.com/a.jpg'),
        altText: 'Foto "bella"',
      );
      expect(html, contains('<!-- wp:image {"id":5'));
      expect(html, contains('alt="Foto &quot;bella&quot;"'));
      expect(html, contains('<p>Uno &lt;b&gt;<br>riga due</p>'));
      expect(html, contains('Due &amp; "tre"'));
      expect('<!-- wp:paragraph -->'.allMatches(html), hasLength(2));
    });
  });

  test('mimeTypeForFileName', () {
    expect(mimeTypeForFileName('a.JPEG'), 'image/jpeg');
    expect(mimeTypeForFileName('a.png'), 'image/png');
    expect(mimeTypeForFileName('a.heic'), 'image/heic');
    expect(mimeTypeForFileName('noext'), 'application/octet-stream');
  });
}
