import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

Future<bool?> showRestoreConfirmation(BuildContext context) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS => showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Replace local blends?'),
          content: const Text(
            'Restoring a backup replaces current blends. You can undo until your next edit.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Restore'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
      TargetPlatform.windows => fluent.showDialog<bool>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Replace local blends?'),
          content: const Text(
            'Restoring a backup replaces current blends. You can undo until your next edit.',
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            fluent.FilledButton(
              child: const Text('Restore'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
      _ => material.showDialog<bool>(
        context: context,
        builder: (context) => material.AlertDialog(
          title: const Text('Replace local blends?'),
          content: const Text(
            'Restoring a backup replaces current blends. You can undo until your next edit.',
          ),
          actions: [
            material.TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            material.FilledButton(
              child: const Text('Restore'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    };
