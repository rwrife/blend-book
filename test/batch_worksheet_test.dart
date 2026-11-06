import 'package:blend_book/batch_worksheet.dart';
import 'package:blend_book/blend_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Revision revision(List<Ingredient> ingredients) => Revision(
    id: 'revision-1',
    createdAt: DateTime.utc(2026),
    ingredients: ingredients,
    notes: '',
  );
  final rub = revision([
    Ingredient(name: 'Paprika', amount: 0.125, unit: 'g'),
    Ingredient(name: 'Cumin', amount: 2, unit: 'kg'),
  ]);

  test('fractions and explicit half-up rounding', () {
    final worksheet = BatchWorksheet.scale(
      revision: rub,
      sourceBatch: '0.5',
      targetBatch: '1.5',
      batchUnit: 'g',
      places: 2,
    );
    expect(worksheet.revisionId, 'revision-1');
    expect(worksheet.sourceBatch, '0.5');
    expect(worksheet.targetBatch, '1.5');
    expect(worksheet.lines.map((line) => line.amount), ['0.38', '6']);
    expect(worksheet.lines.first.unit, 'g');
  });

  test('repeat scaling uses source revision, not rounded worksheet', () {
    final first = BatchWorksheet.scale(
      revision: rub,
      sourceBatch: '3',
      targetBatch: '1',
      batchUnit: 'g',
      places: 2,
    );
    final second = BatchWorksheet.scale(
      revision: rub,
      sourceBatch: '3',
      targetBatch: '6',
      batchUnit: 'g',
      places: 2,
    );
    final repeated = BatchWorksheet.scale(
      revision: rub,
      sourceBatch: '3',
      targetBatch: '1',
      batchUnit: 'g',
      places: 2,
    );
    expect(first.lines.first.amount, '0.04');
    expect(second.lines.first.amount, '0.25');
    expect(repeated.lines.first.amount, first.lines.first.amount);
    expect(rub.ingredients.first.amount, 0.125);
  });

  test('invalid targets, units, and precision reject', () {
    for (final target in ['0', '-1', 'NaN', '1e2', '1.1234567']) {
      expect(
        () => BatchWorksheet.scale(
          revision: rub,
          sourceBatch: '1',
          targetBatch: target,
          batchUnit: 'g',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => BatchWorksheet.scale(
        revision: rub,
        sourceBatch: '0',
        targetBatch: '1',
        batchUnit: 'g',
      ),
      throwsFormatException,
    );
    expect(
      () => BatchWorksheet.scale(
        revision: rub,
        sourceBatch: '1',
        targetBatch: '2',
        batchUnit: 'cup',
      ),
      throwsFormatException,
    );
    expect(
      () => BatchWorksheet.scale(
        revision: rub,
        sourceBatch: '1',
        targetBatch: '2',
        batchUnit: 'stone',
      ),
      throwsFormatException,
    );
    expect(
      () => BatchWorksheet.scale(
        revision: rub,
        sourceBatch: '1',
        targetBatch: '2',
        batchUnit: 'g',
        places: 7,
      ),
      throwsRangeError,
    );
  });

  test('exact decimal division and half-up tie', () {
    expect((Quantity.parse('1') / Quantity.parse('8')).round(2), '0.13');
    expect((Quantity.parse('1') / Quantity.parse('8')).round(3), '0.125');
    expect((Quantity.parse('2') / Quantity.parse('3')).round(2), '0.67');
  });
}
