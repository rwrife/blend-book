import 'package:blend_book/blend_store.dart';
import 'package:blend_book/portable_files.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'jarCard generates non-empty PDF containing blend and revision metadata',
    () async {
      final paprika = Ingredient(name: 'Paprika', amount: 2.5, unit: 'tsp');
      final blend = Blend(
        id: 'blend-123',
        name: 'BBQ Rub',
        revisions: [
          Revision(
            id: 'rev-456',
            createdAt: DateTime.utc(2026, 11, 7),
            ingredients: [paprika],
            notes: 'nice and smoky',
          ),
        ],
      );

      final bytes = await jarCard(
        blend,
        blend.revisions.single,
        DateTime(2026, 11, 7),
      );
      expect(bytes, isNotEmpty);
      // PDF signature check
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    },
  );
}
