import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'blend_store.dart';

Future<Uint8List> jarCard(
  Blend blend,
  Revision revision,
  DateTime batchDate,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            blend.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Revision: ${revision.id}'),
          pw.Text(
            'Batch date: ${batchDate.year.toString().padLeft(4, '0')}-${batchDate.month.toString().padLeft(2, '0')}-${batchDate.day.toString().padLeft(2, '0')}',
          ),
          pw.SizedBox(height: 12),
          for (final item in revision.ingredients)
            pw.Text('${item.name}: ${item.amount} ${item.unit}'),
        ],
      ),
    ),
  );
  return doc.save();
}

Future<void> saveOwnedFile(
  BuildContext context,
  String name,
  String mimeType,
  Uint8List bytes,
) async {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } else {
    final location = await getSaveLocation(suggestedName: name);
    if (location != null) {
      await XFile.fromData(
        bytes,
        mimeType: mimeType,
        name: name,
      ).saveTo(location.path);
    }
  }
}

Future<void> restoreOwnedFile(BlendStore store) async {
  const jsonType = XTypeGroup(
    label: 'Blend Book backup',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final file = await openFile(acceptedTypeGroups: [jsonType]);
  if (file == null) return;
  // Read at most 10 MiB plus one byte; never allocate unbounded imported files.
  final bytes = <int>[];
  await for (final chunk in file.openRead()) {
    bytes.addAll(chunk);
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Store too large');
    }
  }
  await store.restore(bytes);
}
