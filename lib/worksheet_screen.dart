import 'package:flutter/widgets.dart';

import 'batch_worksheet.dart';
import 'main.dart';

class WorksheetScreen extends StatelessWidget {
  const WorksheetScreen({super.key, required this.worksheet});

  final BatchWorksheet worksheet;

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    title: 'Batch worksheet',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Source revision: ${worksheet.revisionId}'),
        Text('Source batch: ${worksheet.sourceBatch} ${worksheet.batchUnit}'),
        Text('Target batch: ${worksheet.targetBatch} ${worksheet.batchUnit}'),
        for (final line in worksheet.lines)
          Semantics(
            label: '${line.name}: ${line.amount} ${line.unit}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${line.name}: ${line.amount} ${line.unit}'),
            ),
          ),
      ],
    ),
  );
}
