import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'batch_worksheet.dart';
import 'blend_store.dart';
import 'main.dart';
import 'worksheet_screen.dart';

class BlendScreen extends StatefulWidget {
  const BlendScreen({super.key, required this.store});
  final BlendStore store;

  @override
  State<BlendScreen> createState() => _BlendScreenState();
}

class _BlendScreenState extends State<BlendScreen> {
  String? selectedId;
  String? error;

  Blend? get selected {
    for (final blend in widget.store.blends) {
      if (blend.id == selectedId) return blend;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final availableWidth = MediaQuery.sizeOf(context).width;
    final listWidth = availableWidth < 740 ? availableWidth * 0.4 : 300.0;
    final list = ListView(
      children: [
        if (widget.store.blends.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No blends yet. Create one to begin.'),
          ),
        for (final blend in widget.store.blends)
          Padding(
            padding: const EdgeInsets.all(4),
            child: AdaptiveButton(
              label: '${blend.name} (${blend.revisions.length} revisions)',
              onPressed: () {
                setState(() => selectedId = blend.id);
                if (!wide) {
                  Navigator.of(context).push(
                    adaptiveRoute(
                      builder: (_) => AdaptiveScaffold(
                        title: blend.name,
                        body: _Detail(
                          store: widget.store,
                          blendId: blend.id,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
    return AdaptiveScaffold(
      title: 'Blend Book',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AdaptiveButton(label: 'New blend', onPressed: () => _edit()),
          ),
          if (error != null) Text(error!, key: const Key('blend-error')),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: listWidth, child: list),
                      const SizedBox(
                        width: 1,
                        child: ColoredBox(color: Color(0x33888888)),
                      ),
                      Expanded(
                        child: selected == null
                            ? const Center(child: Text('Select a blend'))
                            : _Detail(
                                store: widget.store,
                                blendId: selectedId!,
                                onChanged: () => setState(() {}),
                              ),
                      ),
                    ],
                  )
                : list,
          ),
        ],
      ),
    );
  }

  Future<void> _edit() async {
    final result = await showBlendForm(context);
    if (result == null || !mounted) return;
    try {
      final created = await widget.store.create(
        result.name,
        result.ingredients,
        notes: result.notes,
      );
      if (mounted) {
        setState(() {
          selectedId = created.id;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.store,
    required this.blendId,
    required this.onChanged,
  });
  final BlendStore store;
  final String blendId;
  final VoidCallback onChanged;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final blend = widget.store.blends.firstWhere((b) => b.id == widget.blendId);
    final revision = blend.revisions.last;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          blend.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text('Current revision: ${revision.id}'),
        Text('Tasting notes: ${revision.notes}'),
        for (final item in revision.ingredients)
          Text('${item.name}: ${item.amount} ${item.unit}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdaptiveButton(
              label: 'Revise',
              onPressed: () async {
                final result = await showBlendForm(
                  context,
                  name: blend.name,
                  revision: revision,
                );
                if (result == null || !mounted) return;
                try {
                  await widget.store.revise(
                    blend.id,
                    result.ingredients,
                    notes: result.notes,
                  );
                  if (mounted) {
                    setState(() => error = null);
                    widget.onChanged();
                  }
                } catch (e) {
                  if (mounted) setState(() => error = e.toString());
                }
              },
            ),
            AdaptiveButton(
              label: 'Scale batch',
              onPressed: () async {
                final amounts = await showScaleForm(context);
                if (amounts == null || !mounted) return;
                try {
                  final worksheet = BatchWorksheet.scale(
                    revision: revision,
                    sourceBatch: amounts.$1,
                    targetBatch: amounts.$2,
                    batchUnit: revision.ingredients.first.unit,
                  );
                  if (context.mounted) {
                    Navigator.of(context).push(
                      adaptiveRoute(
                        builder: (_) => WorksheetScreen(worksheet: worksheet),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) setState(() => error = e.toString());
                }
              },
            ),
          ],
        ),
        if (error != null) Text(error!, key: const Key('detail-error')),
        const SizedBox(height: 20),
        const Text(
          'Revision history',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        for (final prior in blend.revisions.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${prior.createdAt.toLocal().toString().split('.').first} — '
              '${prior.id} — ${prior.notes} — '
              '${prior.ingredients.map((i) => '${i.name}: ${i.amount} ${i.unit}').join(', ')}',
            ),
          ),
      ],
    );
  }
}

class BlendFormResult {
  BlendFormResult(this.name, this.notes, this.ingredients);
  final String name;
  final String notes;
  final List<Ingredient> ingredients;
}

Future<BlendFormResult?> showBlendForm(
  BuildContext context, {
  String? name,
  Revision? revision,
}) => showNativeForm<BlendFormResult>(
  context,
  builder: (_) => _BlendForm(name: name, revision: revision),
);

class _BlendForm extends StatefulWidget {
  const _BlendForm({this.name, this.revision});
  final String? name;
  final Revision? revision;
  @override
  State<_BlendForm> createState() => _BlendFormState();
}

class _BlendFormState extends State<_BlendForm> {
  late final TextEditingController name = TextEditingController(
    text: widget.name ?? '',
  );
  late final TextEditingController notes = TextEditingController(
    text: widget.revision?.notes ?? '',
  );
  late final List<
    ({TextEditingController name, TextEditingController amount, String unit})
  >
  rows = widget.revision == null
      ? [
          (
            name: TextEditingController(),
            amount: TextEditingController(),
            unit: 'g',
          ),
        ]
      : [
          for (final ingredient in widget.revision!.ingredients)
            (
              name: TextEditingController(text: ingredient.name),
              amount: TextEditingController(text: ingredient.amount.toString()),
              unit: ingredient.unit,
            ),
        ];
  String? error;
  static const units = ['g', 'kg', 'mg', 'tsp', 'tbsp', 'cup', 'ml', 'l'];

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    for (final row in rows) {
      row.name.dispose();
      row.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.revision == null ? 'New blend' : 'Revise blend',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          if (widget.revision == null)
            nativeField(name, 'Blend name')
          else
            Text(widget.name!),
          nativeField(notes, 'Tasting notes'),
          for (int index = 0; index < rows.length; index++)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingredient ${index + 1}'),
                nativeField(rows[index].name, 'Ingredient name'),
                nativeField(rows[index].amount, 'Amount'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final candidate in units)
                      AdaptiveButton(
                        label: candidate == rows[index].unit
                            ? '✓ $candidate'
                            : candidate,
                        onPressed: () => setState(
                          () => rows[index] = (
                            name: rows[index].name,
                            amount: rows[index].amount,
                            unit: candidate,
                          ),
                        ),
                      ),
                  ],
                ),
                if (rows.length > 1)
                  AdaptiveButton(
                    label: 'Remove ingredient ${index + 1}',
                    onPressed: () => setState(() {
                      final removed = rows.removeAt(index);
                      removed.name.dispose();
                      removed.amount.dispose();
                    }),
                  ),
              ],
            ),
          AdaptiveButton(
            label: 'Add ingredient',
            onPressed: () => setState(() {
              rows.add((
                name: TextEditingController(),
                amount: TextEditingController(),
                unit: rows.first.unit,
              ));
            }),
          ),
          if (error != null) Text(error!, key: const Key('form-error')),
          AdaptiveButton(
            label: 'Save blend',
            onPressed: () {
              try {
                final items = [
                  for (final row in rows)
                    Ingredient(
                      name: row.name.text,
                      amount: double.parse(row.amount.text),
                      unit: row.unit,
                    ),
                ];
                if (name.text.trim().isEmpty) {
                  throw const FormatException('Blend name required');
                }
                Navigator.of(context)
                    .pop(BlendFormResult(name.text, notes.text, items));
              } catch (e) {
                setState(() => error = e.toString());
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<(String, String)?> showScaleForm(BuildContext context) =>
    showNativeForm<(String, String)>(
      context,
      builder: (_) => const _ScaleForm(),
    );

class _ScaleForm extends StatefulWidget {
  const _ScaleForm();
  @override
  State<_ScaleForm> createState() => _ScaleFormState();
}

class _ScaleFormState extends State<_ScaleForm> {
  final source = TextEditingController(text: '1');
  final target = TextEditingController(text: '2');
  @override
  void dispose() {
    source.dispose();
    target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Scale batch', style: TextStyle(fontSize: 20)),
        nativeField(source, 'Source batch'),
        nativeField(target, 'Target batch'),
        AdaptiveButton(
          label: 'Generate worksheet',
          onPressed: () =>
              Navigator.of(context).pop((source.text, target.text)),
        ),
      ],
    ),
  );
}

Widget nativeField(TextEditingController controller, String label) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoTextField(
      controller: controller,
      placeholder: label,
      padding: const EdgeInsets.all(12),
    ),
    TargetPlatform.windows => fluent.TextBox(
      controller: controller,
      placeholder: label,
    ),
    _ => material.TextField(
      controller: controller,
      decoration: material.InputDecoration(labelText: label),
    ),
  },
);

Route<T> adaptiveRoute<T>({required WidgetBuilder builder}) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS => CupertinoPageRoute<T>(builder: builder),
      TargetPlatform.windows => fluent.FluentPageRoute<T>(builder: builder),
      _ => material.MaterialPageRoute<T>(builder: builder),
    };

Future<T?> showNativeForm<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) =>
        CupertinoPopupSurface(child: SafeArea(child: builder(ctx))),
  ),
  TargetPlatform.windows => fluent.showDialog<T>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(content: builder(ctx)),
  ),
  _ => material.showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  ),
};
