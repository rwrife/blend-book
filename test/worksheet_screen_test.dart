import 'package:blend_book/batch_worksheet.dart';
import 'package:blend_book/blend_store.dart';
import 'package:blend_book/worksheet_screen.dart';
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
    testWidgets('$platform worksheet displays source revision and amounts', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final revision = Revision(
          id: 'saved-revision-42',
          createdAt: DateTime.utc(2026),
          ingredients: [Ingredient(name: 'Cumin', amount: 0.125, unit: 'g')],
          notes: '',
        );
        final screen = WorksheetScreen(
          worksheet: BatchWorksheet.scale(
            revision: revision,
            sourceBatch: '0.5',
            targetBatch: '1.5',
            batchUnit: 'g',
          ),
        );
        await tester.pumpWidget(switch (platform) {
          TargetPlatform.iOS => CupertinoApp(home: screen),
          TargetPlatform.windows => fluent.FluentApp(home: screen),
          _ => material.MaterialApp(home: screen),
        });
        expect(find.text('Source revision: saved-revision-42'), findsOneWidget);
        expect(find.text('Source batch: 0.5 g'), findsOneWidget);
        expect(find.text('Target batch: 1.5 g'), findsOneWidget);
        expect(find.text('Cumin: 0.38 g'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
