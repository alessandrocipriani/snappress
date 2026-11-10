// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import '../publisher.dart';
import 'wordpress_client.dart';
import 'wordpress_content.dart';

/// Publishes to WordPress: upload image → set alt text → create post.
class WordPressPublisher implements Publisher {
  WordPressPublisher(this._client);

  final WordPressClient _client;

  /// URL of the last uploaded image. Phase 3 reuses it for Instagram,
  /// which only accepts images by public URL.
  Uri? lastImageUrl;

  @override
  String get id => 'wordpress';

  @override
  Future<bool> testConnection() async {
    try {
      final user = await _client.currentUser();
      return user.canUploadFiles;
    } on WordPressException {
      return false;
    }
  }

  @override
  Future<PublishResult> publish(PostDraft draft) async {
    try {
      final media = await _client.uploadMedia(
        bytes: draft.imageBytes,
        fileName: draft.imageFileName,
        mimeType: draft.imageMimeType,
      );
      lastImageUrl = media.sourceUrl;

      final altText = draft.altText?.trim() ?? '';
      if (altText.isNotEmpty) {
        await _client.setMediaAltText(media.id, altText);
      }

      final post = await _client.createPost(
        title: draft.title?.trim() ?? '',
        content: buildWordPressContent(
          body: draft.body,
          mediaId: media.id,
          imageUrl: media.sourceUrl,
          altText: altText,
          hashtags: draft.hashtags,
        ),
        status: draft.asDraft ? 'draft' : 'publish',
        featuredMediaId: media.id,
      );
      return PublishResult.success(url: post.link);
    } on WordPressException catch (e) {
      return PublishResult.failure(e.message);
    }
  }
}
