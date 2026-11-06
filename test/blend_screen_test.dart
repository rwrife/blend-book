import 'dart:io';

import 'package:blend_book/blend_store.dart';
import 'package:blend_book/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final width in [390.0, 900.0, 1440.0]) {
      testWidgets('$platform $width browse and native editor', (tester) async {
        final directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('blend-screen-'),
        );
        expect(directory, isNotNull);
        final workDir = directory!;

        debugDefaultTargetPlatformOverride = platform;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        try {
          final store = BlendStore.onDevice(workDir);
          final blend = await tester.runAsync(() async {
            await store.load();
            return store.create('Curry', [
              Ingredient(name: 'Paprika', amount: 2, unit: 'g'),
            ], notes: 'Smoky');
          });
          expect(blend, isNotNull);
          await tester.pumpWidget(BlendBookApp(store: store));
          expect(find.text('Curry (1 revisions)'), findsOneWidget);
          expect(
            find.byType(CupertinoApp),
            platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(fluent.FluentApp),
            platform == TargetPlatform.windows ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(material.MaterialApp),
            platform == TargetPlatform.android ? findsOneWidget : findsNothing,
          );
          await tester.tap(find.text('Curry (1 revisions)'));
          await tester.pumpAndSettle();
          expect(
            find.text('Current revision: ${blend!.revisions.last.id}'),
            findsOneWidget,
          );
          await tester.tap(find.text('Revise'));
          await tester.pumpAndSettle();
          expect(find.text('Revise blend'), findsOneWidget);
          expect(
            find.byType(CupertinoTextField),
            platform == TargetPlatform.iOS ? findsWidgets : findsNothing,
          );
          expect(
            find.byType(fluent.TextBox),
            platform == TargetPlatform.windows ? findsWidgets : findsNothing,
          );
          expect(
            find.byType(material.TextField),
            platform == TargetPlatform.android ? findsWidgets : findsNothing,
          );
          expect(tester.takeException(), isNull);

          // Accessibility check: scalable text at 2x does not throw/overflow.
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;
          await tester.pump();
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          debugDefaultTargetPlatformOverride = null;
          await tester.runAsync(() => workDir.delete(recursive: true));
        }
      });
    }
  }
}
