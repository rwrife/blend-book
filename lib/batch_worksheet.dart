import 'blend_store.dart';

/// Exact decimal fraction. No binary floating-point arithmetic during scaling.
class Quantity {
  Quantity._(this.numerator, this.denominator);

  final BigInt numerator;
  final BigInt denominator;

  factory Quantity.parse(String text) {
    if (!RegExp(r'^\d+(?:\.\d{1,6})?$').hasMatch(text)) {
      throw const FormatException(
        'Use a nonnegative decimal with up to 6 places',
      );
    }
    final parts = text.split('.');
    final scale = BigInt.from(10).pow(parts.length == 2 ? parts[1].length : 0);
    final numerator =
        BigInt.parse(parts[0]) * scale +
        (parts.length == 2 ? BigInt.parse(parts[1]) : BigInt.zero);
    return Quantity._(numerator, scale);
  }

  Quantity operator *(Quantity other) =>
      Quantity._(numerator * other.numerator, denominator * other.denominator);

  Quantity operator /(Quantity other) {
    if (other.numerator == BigInt.zero) {
      throw const FormatException('Zero source batch');
    }
    return Quantity._(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  /// Half-up, explicit decimal places; render without trailing fractional zeros.
  String round(int places) {
    if (places < 0 || places > 6) throw RangeError.range(places, 0, 6);
    final factor = BigInt.from(10).pow(places);
    final scaled =
        (numerator * factor * BigInt.two + denominator) ~/
        (denominator * BigInt.two);
    if (places == 0) return scaled.toString();
    final whole = scaled ~/ factor;
    final fraction = (scaled % factor)
        .toString()
        .padLeft(places, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }
}

class WorksheetLine {
  const WorksheetLine(this.name, this.amount, this.unit);
  final String name;
  final String amount;
  final String unit;
}

class BatchWorksheet {
  BatchWorksheet._(
    this.revisionId,
    this.sourceBatch,
    this.targetBatch,
    this.batchUnit,
    this.lines,
  );

  final String revisionId;
  final String sourceBatch;
  final String targetBatch;
  final String batchUnit;
  final List<WorksheetLine> lines;

  factory BatchWorksheet.scale({
    required Revision revision,
    required String sourceBatch,
    required String targetBatch,
    required String batchUnit,
    int places = 2,
  }) {
    const mass = {'g', 'kg', 'mg'};
    const volume = {'tsp', 'tbsp', 'cup', 'ml', 'l'};
    if (!mass.contains(batchUnit) && !volume.contains(batchUnit)) {
      throw const FormatException('Unknown batch unit');
    }
    if (revision.ingredients.any(
      (item) => mass.contains(batchUnit)
          ? !mass.contains(item.unit)
          : !volume.contains(item.unit),
    )) {
      throw const FormatException('Incompatible mass/volume units');
    }
    final source = Quantity.parse(sourceBatch);
    final target = Quantity.parse(targetBatch);
    if (source.numerator == BigInt.zero || target.numerator == BigInt.zero) {
      throw const FormatException('Batch amounts must be positive');
    }
    if (places < 0 || places > 6) throw RangeError.range(places, 0, 6);
    final ratio = target / source;
    // ponytail: Persist decimal amounts as numbers for legacy models; parse their
    // shortest decimal strings here. Add string-backed amounts if >6-place input is needed.
    final lines = revision.ingredients
        .map(
          (item) => WorksheetLine(
            item.name,
            (Quantity.parse(item.amount.toString()) * ratio).round(places),
            item.unit,
          ),
        )
        .toList(growable: false);
    return BatchWorksheet._(
      revision.id,
      sourceBatch,
      targetBatch,
      batchUnit,
      List.unmodifiable(lines),
    );
  }
}
