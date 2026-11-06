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
    testWidgets('$platform uses native shell, button and dialog', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(const BlendBookApp());
        expect(find.text('Your blends stay on this device.'), findsOneWidget);
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
        expect(
          find.byType(fluent.NavigationView),
          platform == TargetPlatform.windows ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(
          platform == TargetPlatform.iOS
              ? CupertinoApp(home: CupertinoPageScaffold(child: _Actions()))
              : platform == TargetPlatform.windows
              ? fluent.FluentApp(home: _Actions())
              : material.MaterialApp(home: material.Scaffold(body: _Actions())),
        );
        expect(
          find.byType(CupertinoButton),
          platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(fluent.Button),
          platform == TargetPlatform.windows ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(material.FilledButton),
          platform == TargetPlatform.android ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(
          find.byType(CupertinoAlertDialog),
          platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(fluent.ContentDialog),
          platform == TargetPlatform.windows ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(material.AlertDialog),
          platform == TargetPlatform.android ? findsOneWidget : findsNothing,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) => AdaptiveButton(
    label: 'Open',
    onPressed: () => showAdaptiveDialog(context, 'Local only'),
  );
}
