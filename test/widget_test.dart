// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snappress/app.dart';

void main() {
  testWidgets('home screen is translated in Italian', (tester) async {
    await tester.pumpWidget(const SnapPressApp(locale: Locale('it')));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo post'), findsOneWidget);
    expect(find.byTooltip('Impostazioni'), findsOneWidget);
  });

  testWidgets('home screen is translated in English', (tester) async {
    await tester.pumpWidget(const SnapPressApp(locale: Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('New post'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('settings screen opens and lists licences', (tester) async {
    await tester.pumpWidget(const SnapPressApp(locale: Locale('it')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(find.text('Licenze open source'), findsOneWidget);
  });

  testWidgets('home screen meets accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const SnapPressApp(locale: Locale('it')));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    semantics.dispose();
  });
}
