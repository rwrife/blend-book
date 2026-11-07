import 'dart:convert';
import 'dart:io';

import 'package:blend_book/blend_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late BlendStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('blend-book-');
    store = BlendStore.onDevice(directory);
    await store.load();
  });
  tearDown(() async => directory.delete(recursive: true));

  final paprika = Ingredient(name: 'Paprika', amount: 2, unit: 'tsp');
  final cumin = Ingredient(name: 'Cumin', amount: 1, unit: 'tbsp');

  test(
    'create, revise, restart: immutable history and dates survive',
    () async {
      final input = [paprika];
      final first = await store.create('Smoky rub', input, notes: 'bright');
      input.add(cumin);
      expect(first.revisions.single.ingredients, hasLength(1));
      final revised = await store.revise(first.id, [
        paprika,
        cumin,
      ], notes: 'warmer');
      expect(revised.revisions, hasLength(2));
      expect(revised.revisions.first.id, first.revisions.single.id);
      expect(revised.revisions.first.notes, 'bright');
      expect(
        () => revised.revisions.first.ingredients.add(cumin),
        throwsUnsupportedError,
      );
      expect(
        () => revised.revisions.add(revised.revisions.first),
        throwsUnsupportedError,
      );

      final reopened = BlendStore.onDevice(directory);
      await reopened.load();
      expect(reopened.blends.single.revisions.map((r) => r.notes), [
        'bright',
        'warmer',
      ]);
      expect(
        reopened.blends.single.revisions.last.ingredients.last.unit,
        'tbsp',
      );
      expect(
        reopened.blends.single.revisions.first.createdAt.toUtc(),
        revised.revisions.first.createdAt.toUtc(),
      );
    },
  );

  test(
    'invalid ingredients and revisions leave persisted data unchanged',
    () async {
      final prior = await store.create('Rub', [paprika]);
      final bytes = await store.file.readAsBytes();
      expect(
        () => Ingredient(name: ' ', amount: 1, unit: 'g'),
        throwsFormatException,
      );
      expect(
        () => Ingredient(name: 'Salt', amount: double.nan, unit: 'g'),
        throwsFormatException,
      );
      expect(
        () => Ingredient(name: 'Salt', amount: 0, unit: 'g'),
        throwsFormatException,
      );
      expect(
        () => Ingredient(name: 'Salt', amount: 1, unit: 'stone'),
        throwsFormatException,
      );
      await expectLater(
        store.revise(prior.id, [
          paprika,
          Ingredient(name: 'Salt', amount: 1, unit: 'g'),
        ]),
        throwsFormatException,
      );
      await expectLater(store.revise('missing', [paprika]), throwsStateError);
      await expectLater(store.create('Empty', []), throwsFormatException);
      expect(await store.file.readAsBytes(), bytes);
      expect(store.blends.single.revisions, hasLength(1));
    },
  );

  test('migration 1 normalizes title, writes 2 only on next edit', () async {
    final prior = await store.create('Rub', [paprika]);
    final old =
        jsonDecode(await store.file.readAsString()) as Map<String, dynamic>;
    final blend = (old['blends'] as List).single as Map<String, dynamic>;
    blend['title'] = blend.remove('name');
    old['schemaVersion'] = 1;
    await store.file.writeAsString(jsonEncode(old));
    final restarted = BlendStore.onDevice(directory);
    await restarted.load();
    expect(restarted.blends.single.name, 'Rub');
    expect(
      restarted.blends.single.revisions.single.id,
      prior.revisions.single.id,
    );
    expect(jsonDecode(await store.file.readAsString())['schemaVersion'], 1);
    await restarted.revise(prior.id, [paprika]);
    expect(jsonDecode(await store.file.readAsString())['schemaVersion'], 2);
  });

  test('recovers prior snapshot when primary file is missing', () async {
    final blend = await store.create('Rub', [paprika]);
    await store.file.rename('${store.file.path}.previous');
    final restarted = BlendStore.onDevice(directory);
    await restarted.load();
    expect(restarted.blends.single.id, blend.id);
    expect(await store.file.exists(), isTrue);
  });

  test(
    'overlapping writes reject stale snapshot without losing data',
    () async {
      final first = store.create('Rub', [paprika]);
      await expectLater(store.create('Second', [cumin]), throwsStateError);
      final created = await first;
      final restarted = BlendStore.onDevice(directory);
      await restarted.load();
      expect(restarted.blends.single.id, created.id);
    },
  );

  test(
    'export and restore roundtrip retains revisions and prior backup',
    () async {
      final first = await store.create('Rub', [paprika]);
      await store.revise(first.id, [paprika, cumin]);
      final exported = store.exportBytes();
      await store.create('Second', [cumin]);
      final beforeRestore = await store.file.readAsBytes();
      await store.restore(exported);
      expect(store.blends, hasLength(1));
      expect(store.blends.single.revisions, hasLength(2));
      expect(
        await File('${store.file.path}.restore-backup').readAsBytes(),
        beforeRestore,
      );
      final reopened = BlendStore.onDevice(directory);
      await reopened.load();
      expect(reopened.blends.single.id, first.id);
      await store.rollbackRestore();
      expect(await store.file.readAsBytes(), beforeRestore);
      expect(store.blends, hasLength(2));
      expect(await File('${store.file.path}.restore-backup').exists(), isFalse);
    },
  );

  test('restore on empty store can be undone', () async {
    final source = BlendStore.onDevice(Directory('${directory.path}/source'));
    await source.load();
    final blend = await source.create('Other', [paprika]);
    await store.restore(source.exportBytes());
    expect(store.blends.single.id, blend.id);
    expect(store.canUndoRestore, isTrue);
    await store.rollbackRestore();
    expect(store.blends, isEmpty);
    expect(store.canUndoRestore, isFalse);
  });

  test('restore failure leaves live store unchanged', () async {
    final first = await store.create('Rub', [paprika]);
    final prior = await store.file.readAsBytes();
    await expectLater(
      store.restore(utf8.encode('{corrupted json')),
      throwsFormatException,
    );
    expect(await store.file.readAsBytes(), prior);
    expect(store.blends.single.id, first.id);
  });

  test('rollback throws state error when no restore has occurred', () async {
    await expectLater(store.rollbackRestore(), throwsStateError);
  });

  test(
    'malformed and oversized restore leave disk and memory unchanged',
    () async {
      final first = await store.create('Rub', [paprika]);
      final prior = await store.file.readAsBytes();
      await expectLater(
        store.restore(utf8.encode('{bad')),
        throwsFormatException,
      );
      await expectLater(
        store.restore(List.filled(10 * 1024 * 1024 + 1, 32)),
        throwsFormatException,
      );
      final duplicate = jsonDecode(utf8.decode(prior)) as Map<String, dynamic>;
      duplicate['blends'] = [duplicate['blends'][0], duplicate['blends'][0]];
      await expectLater(
        store.restore(utf8.encode(jsonEncode(duplicate))),
        throwsFormatException,
      );
      expect(await store.file.readAsBytes(), prior);
      expect(store.blends.single.id, first.id);
    },
  );

  test('bad schema and references never replace live state', () async {
    final prior = await store.create('Rub', [paprika]);
    final data =
        jsonDecode(await store.file.readAsString()) as Map<String, dynamic>;
    data['schemaVersion'] = 99;
    await store.file.writeAsString(jsonEncode(data));
    await expectLater(store.load(), throwsFormatException);
    expect(store.blends.single.id, prior.id);
    data['schemaVersion'] = 2;
    data['blends'] = [data['blends'][0], data['blends'][0]];
    await store.file.writeAsString(jsonEncode(data));
    await expectLater(store.load(), throwsFormatException);
    expect(store.blends, hasLength(1));
    await store.file.writeAsString('{broken');
    await expectLater(store.load(), throwsFormatException);
    expect(store.blends.single.id, prior.id);
  });
}
