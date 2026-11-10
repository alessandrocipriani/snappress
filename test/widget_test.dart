// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snappress/app.dart';

import 'helpers.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String? password,
  bool unlocked = false,
  String locale = 'it',
}) async {
  final services =
      await createTestServices(password: password, unlocked: unlocked);
  await tester.pumpWidget(
    SnapPressApp(services: services, locale: Locale(locale)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('lock', () {
    testWidgets('first launch asks to create a password', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Proteggi SnapPress'), findsOneWidget);
      expect(find.text('Nuovo post'), findsNothing);
    });

    testWidgets('setup validates and then opens the app', (tester) async {
      await _pumpApp(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '123');
      await tester.enterText(fields.at(1), '123');
      await tester.tap(find.text('Salva e continua'));
      await tester.pumpAndSettle();
      expect(
        find.text('La password deve avere almeno 6 caratteri'),
        findsOneWidget,
      );

      await tester.enterText(fields.at(0), 'segreta1');
      await tester.enterText(fields.at(1), 'segreta1');
      await tester.tap(find.text('Salva e continua'));
      await tester.pumpAndSettle();

      expect(find.text('Nuovo post'), findsOneWidget);
    });

    testWidgets('wrong password is rejected, right one unlocks',
        (tester) async {
      await _pumpApp(tester, password: 'segreta1');
      expect(find.text('SnapPress è bloccata'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'sbagliata');
      await tester.tap(find.text('Sblocca'));
      await tester.pumpAndSettle();
      expect(find.text('Password errata'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'segreta1');
      await tester.tap(find.text('Sblocca'));
      await tester.pumpAndSettle();
      expect(find.text('Nuovo post'), findsOneWidget);
    });

    testWidgets('lock screen meets accessibility guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpApp(tester, password: 'segreta1');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('unlocked app', () {
    testWidgets('home is translated in Italian and English', (tester) async {
      await _pumpApp(tester, password: 'segreta1', unlocked: true);
      expect(find.text('Nuovo post'), findsOneWidget);
      expect(find.byTooltip('Impostazioni'), findsOneWidget);

      await _pumpApp(
        tester,
        password: 'segreta1',
        unlocked: true,
        locale: 'en',
      );
      expect(find.text('New post'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('home meets accessibility guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpApp(tester, password: 'segreta1', unlocked: true);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('settings lists WordPress and lock now', (tester) async {
      await _pumpApp(tester, password: 'segreta1', unlocked: true);

      await tester.tap(find.byTooltip('Impostazioni'));
      await tester.pumpAndSettle();
      expect(find.text('WordPress'), findsOneWidget);

      await tester.tap(find.text('Blocca ora'));
      await tester.pumpAndSettle();
      expect(find.text('SnapPress è bloccata'), findsOneWidget);
    });

    testWidgets('composer asks to connect WordPress', (tester) async {
      // Tall screen so the whole (lazy) form is built.
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpApp(tester, password: 'segreta1', unlocked: true);

      await tester.tap(find.text('Nuovo post'));
      await tester.pumpAndSettle();

      expect(find.text('Collega il tuo sito WordPress per pubblicare'),
          findsOneWidget);
      final publish = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Salva bozza'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(publish.onPressed, isNull);
    });
  });
}
