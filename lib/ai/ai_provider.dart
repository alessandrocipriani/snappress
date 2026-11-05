// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:typed_data';

/// Tone requested for the generated texts.
enum PostTone { informal, professional, enthusiastic }

/// User preferences for text generation.
class GenerationOptions {
  const GenerationOptions({
    required this.languageCode,
    this.tone = PostTone.informal,
    this.maxHashtags = 10,
    this.extraContext,
  });

  /// ISO 639-1 code of the output language, e.g. `it`.
  final String languageCode;
  final PostTone tone;
  final int maxHashtags;

  /// Optional hint from the user ("product launch", "event recap", ...).
  final String? extraContext;
}

/// Texts proposed by the AI, one per destination plus alt text.
class GeneratedTexts {
  const GeneratedTexts({
    required this.title,
    required this.wordpressBody,
    required this.facebookText,
    required this.instagramCaption,
    required this.hashtags,
    required this.altText,
  });

  final String title;
  final String wordpressBody;
  final String facebookText;
  final String instagramCaption;
  final List<String> hashtags;
  final String altText;
}

/// Common interface for AI back-ends (cloud APIs with the user's own key,
/// self-hosted OpenAI-compatible endpoints, on-device models).
abstract interface class AiProvider {
  String get id;

  Future<GeneratedTexts> generate(
    Uint8List image,
    GenerationOptions options,
  );
}
