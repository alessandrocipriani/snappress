// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'dart:convert';

const HtmlEscape _textEscape = HtmlEscape(HtmlEscapeMode.element);
const HtmlEscape _attributeEscape = HtmlEscape(HtmlEscapeMode.attribute);

/// Builds the post body in Gutenberg block markup: the image first, then one
/// paragraph per block of text separated by an empty line.
///
/// User text is HTML-escaped, so typing `<b>` shows `<b>` literally.
String buildWordPressContent({
  required String body,
  required int mediaId,
  required Uri imageUrl,
  String? altText,
  List<String> hashtags = const [],
}) {
  final buffer = StringBuffer()
    ..writeln(
      '<!-- wp:image {"id":$mediaId,"sizeSlug":"large",'
      '"linkDestination":"none"} -->',
    )
    ..writeln(
      '<figure class="wp-block-image size-large">'
      '<img src="${_attributeEscape.convert(imageUrl.toString())}" '
      'alt="${_attributeEscape.convert(altText ?? '')}" '
      'class="wp-image-$mediaId"/></figure>',
    )
    ..writeln('<!-- /wp:image -->');

  final paragraphs = body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  for (final paragraph in paragraphs) {
    _writeParagraph(buffer, paragraph);
  }

  if (hashtags.isNotEmpty) {
    _writeParagraph(buffer, hashtags.map(_asHashtag).join(' '));
  }

  return buffer.toString().trimRight();
}

void _writeParagraph(StringBuffer buffer, String text) {
  final html =
      text.split('\n').map((line) => _textEscape.convert(line)).join('<br>');
  buffer
    ..writeln()
    ..writeln('<!-- wp:paragraph -->')
    ..writeln('<p>$html</p>')
    ..writeln('<!-- /wp:paragraph -->');
}

String _asHashtag(String tag) {
  final clean = tag.trim();
  return clean.startsWith('#') ? clean : '#$clean';
}
