// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.
//
// Fails (exit code 1) if any resolved dependency ships a GPL, LGPL or AGPL
// licence, which would be incompatible with publishing SnapPress under
// BSD-3-Clause on the App Store. Run after `flutter pub get`:
//
//   dart run tool/check_licenses.dart

import 'dart:convert';
import 'dart:io';

const _selfName = 'snappress';

const _forbiddenMarkers = [
  'GNU GENERAL PUBLIC LICENSE',
  'GNU LESSER GENERAL PUBLIC LICENSE',
  'GNU LIBRARY GENERAL PUBLIC LICENSE',
  'GNU AFFERO GENERAL PUBLIC LICENSE',
];

final _licenseFileName = RegExp(r'^(LICEN[SC]E|COPYING)', caseSensitive: false);

void main() {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) {
    stderr
        .writeln('package_config.json not found: run "flutter pub get" first.');
    exit(2);
  }

  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final flutterRoot = config['flutterRoot'] as String?;
  final configUri = configFile.absolute.uri;
  final packages = (config['packages'] as List).cast<Map<String, dynamic>>();

  final problems = <String>[];
  final warnings = <String>[];
  var checked = 0;

  for (final package in packages) {
    final name = package['name'] as String;
    if (name == _selfName) continue;

    final root = configUri.resolve(package['rootUri'] as String);
    // Packages bundled with the Flutter SDK are BSD-3-Clause.
    if (flutterRoot != null && root.toString().startsWith(flutterRoot)) {
      continue;
    }

    final dir = Directory.fromUri(root);
    final Iterable<File> licenseFiles = dir.existsSync()
        ? dir.listSync().whereType<File>().where(
              (f) => _licenseFileName.hasMatch(f.uri.pathSegments.last),
            )
        : const <File>[];

    if (licenseFiles.isEmpty) {
      warnings.add('$name: no LICENSE file found, check it manually');
      continue;
    }

    checked++;
    for (final file in licenseFiles) {
      final text = _read(file).toUpperCase();
      for (final marker in _forbiddenMarkers) {
        if (text.contains(marker)) {
          problems.add('$name (${file.uri.pathSegments.last}): $marker');
        }
      }
    }
  }

  for (final warning in warnings) {
    stdout.writeln('WARNING  $warning');
  }

  if (problems.isNotEmpty) {
    stderr.writeln('Incompatible licences found:');
    for (final problem in problems) {
      stderr.writeln('  - $problem');
    }
    exit(1);
  }

  stdout
      .writeln('OK: $checked third-party packages checked, no GPL/LGPL/AGPL.');
}

String _read(File file) {
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return latin1.decode(file.readAsBytesSync());
  }
}
