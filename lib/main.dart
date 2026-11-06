import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'blend_screen.dart';
import 'blend_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await BlendStore.openOnDevice();
  runApp(BlendBookApp(store: store));
}

class BlendBookApp extends StatelessWidget {
  const BlendBookApp({super.key, this.store});
  final BlendStore? store;

  @override
  Widget build(BuildContext context) {
    final home = store == null
        ? const AdaptiveScaffold(
            title: 'Blend Book',
            body: Center(child: Text('Your blends stay on this device.')),
          )
        : BlendScreen(store: store!);
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => CupertinoApp(title: 'Blend Book', home: home),
      TargetPlatform.windows => fluent.FluentApp(
        title: 'Blend Book',
        home: home,
      ),
      _ => material.MaterialApp(
        title: 'Blend Book',
        theme: material.ThemeData(useMaterial3: true),
        home: home,
      ),
    };
  }
}

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(title)),
        child: SafeArea(child: body),
      ),
      TargetPlatform.windows => fluent.NavigationView(
        content: fluent.ScaffoldPage(
          header: fluent.PageHeader(title: Text(title)),
          content: SafeArea(child: body),
        ),
      ),
      _ => material.Scaffold(
        appBar: material.AppBar(title: Text(title)),
        body: SafeArea(child: body),
      ),
    };
  }
}

class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoButton(
      onPressed: onPressed,
      child: Text(label),
    ),
    TargetPlatform.windows => fluent.Button(
      onPressed: onPressed,
      child: Text(label),
    ),
    _ => material.FilledButton(onPressed: onPressed, child: Text(label)),
  };
}

Future<bool?> showAdaptiveDialog(BuildContext context, String message) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS => showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
      TargetPlatform.windows => fluent.showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          content: Text(message),
          actions: [
            fluent.Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
      _ => material.showDialog<bool>(
        context: context,
        builder: (context) => material.AlertDialog(
          content: Text(message),
          actions: [
            material.TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    };
