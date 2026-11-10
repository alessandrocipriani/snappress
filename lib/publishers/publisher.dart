// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:typed_data';

/// Platform-independent content of a post.
class PostDraft {
  const PostDraft({
    required this.imageBytes,
    required this.imageFileName,
    required this.body,
    this.title,
    this.hashtags = const [],
    this.altText,
    this.asDraft = true,
  });

  final Uint8List imageBytes;
  final String imageFileName;
  final String? title;
  final String body;
  final List<String> hashtags;

  /// Description of the image for screen-reader users.
  final String? altText;

  /// Save as draft instead of publishing immediately (where supported).
  final bool asDraft;

  String get imageMimeType => mimeTypeForFileName(imageFileName);
}

/// Outcome of a publish attempt on one platform.
class PublishResult {
  const PublishResult.success({this.url}) : errorMessage = null;

  const PublishResult.failure(String this.errorMessage) : url = null;

  final Uri? url;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

/// Common interface for every destination (WordPress, Facebook,
/// Instagram, and future ones such as Mastodon or Bluesky).
abstract interface class Publisher {
  /// Stable identifier, e.g. `wordpress`.
  String get id;

  /// Checks that the stored credentials work.
  Future<bool> testConnection();

  Future<PublishResult> publish(PostDraft draft);
}

/// MIME type from the file extension (images only).
String mimeTypeForFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'application/octet-stream',
  };
}
