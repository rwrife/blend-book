import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

const _units = {'g', 'kg', 'mg', 'tsp', 'tbsp', 'cup', 'ml', 'l'};
const _massUnits = {'g', 'kg', 'mg'};

String _name(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 200) {
    throw const FormatException('Name must contain 1–200 characters');
  }
  return value.trim();
}

String _id() => List.generate(
  16,
  (_) => Random.secure().nextInt(256),
).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

class Ingredient {
  Ingredient({required String name, required this.amount, required String unit})
    : name = _name(name),
      unit = _units.contains(unit)
          ? unit
          : (throw const FormatException('Unknown unit')) {
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Amount must be positive and finite');
    }
  }

  final String name;
  final double amount;
  final String unit;

  Map<String, Object> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
  };

  factory Ingredient.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['amount'] is! num ||
        value['unit'] is! String) {
      throw const FormatException('Invalid ingredient');
    }
    return Ingredient(
      name: _name(value['name']),
      amount: (value['amount'] as num).toDouble(),
      unit: value['unit'] as String,
    );
  }
}

class Revision {
  Revision({
    required this.id,
    required this.createdAt,
    required List<Ingredient> ingredients,
    required this.notes,
  }) : ingredients = List.unmodifiable(ingredients) {
    if (id.isEmpty ||
        ingredients.isEmpty ||
        ingredients.length > 100 ||
        notes.length > 5000) {
      throw const FormatException('Invalid revision');
    }
    if (ingredients.map((item) => item.name.toLowerCase()).toSet().length !=
        ingredients.length) {
      throw const FormatException('Duplicate ingredient');
    }
    // ponytail: Keep exact units; add conversion only with user-supplied density.
    if (ingredients.any((item) => _massUnits.contains(item.unit)) &&
        ingredients.any((item) => !_massUnits.contains(item.unit))) {
      throw const FormatException('Mass and volume cannot be mixed');
    }
  }

  final String id;
  final DateTime createdAt;
  final List<Ingredient> ingredients;
  final String notes;

  Map<String, Object> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'notes': notes,
  };

  factory Revision.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['createdAt'] is! String ||
        value['ingredients'] is! List ||
        value['notes'] is! String) {
      throw const FormatException('Invalid revision');
    }
    return Revision(
      id: value['id'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String),
      ingredients: (value['ingredients'] as List)
          .map(Ingredient.fromJson)
          .toList(),
      notes: value['notes'] as String,
    );
  }
}

class Blend {
  Blend({
    required this.id,
    required String name,
    required List<Revision> revisions,
  }) : name = _name(name),
       revisions = List.unmodifiable(revisions) {
    if (id.isEmpty ||
        revisions.isEmpty ||
        revisions.map((r) => r.id).toSet().length != revisions.length) {
      throw const FormatException('Invalid blend history');
    }
  }

  final String id;
  final String name;
  final List<Revision> revisions;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'revisions': revisions.map((r) => r.toJson()).toList(),
  };

  factory Blend.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['revisions'] is! List) {
      throw const FormatException('Invalid blend');
    }
    return Blend(
      id: value['id'] as String,
      name: _name(value['name']),
      revisions: (value['revisions'] as List).map(Revision.fromJson).toList(),
    );
  }
}

class BlendStore {
  BlendStore(this.file);

  final File file;
  List<Blend> _blends = [];
  bool _writing = false;
  List<Blend> get blends => List.unmodifiable(_blends);

  factory BlendStore.onDevice(Directory directory) =>
      BlendStore(File('${directory.path}/blends.json'));

  static Future<BlendStore> openOnDevice() async {
    final store = BlendStore.onDevice(await getApplicationDocumentsDirectory());
    await store.load();
    return store;
  }

  Future<void> load() async {
    if (!await file.exists() && await File('${file.path}.previous').exists()) {
      await File('${file.path}.previous').rename(file.path);
    }
    if (!await file.exists()) {
      _blends = [];
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Store too large');
    }
    final document = jsonDecode(utf8.decode(bytes));
    if (document is! Map<String, dynamic> ||
        document['blends'] is! List ||
        (document['schemaVersion'] != 1 && document['schemaVersion'] != 2)) {
      throw const FormatException('Unsupported store schema');
    }
    // Schema 1 stored blend names as `title`; normalize without rewriting history.
    final entries = (document['blends'] as List)
        .map((entry) {
          if (document['schemaVersion'] == 1 && entry is Map<String, dynamic>) {
            return {...entry, 'name': entry['title']};
          }
          return entry;
        })
        .map(Blend.fromJson)
        .toList();
    if (entries.map((b) => b.id).toSet().length != entries.length) {
      throw const FormatException('Duplicate blend ID');
    }
    _blends = entries;
  }

  Future<Blend> create(
    String name,
    List<Ingredient> ingredients, {
    String notes = '',
  }) async {
    if (_writing) throw StateError('Write already in progress');
    _writing = true;
    try {
      final blend = Blend(
        id: _id(),
        name: name,
        revisions: [
          Revision(
            id: _id(),
            createdAt: DateTime.now().toUtc(),
            ingredients: ingredients,
            notes: notes,
          ),
        ],
      );
      await _save([..._blends, blend]);
      return blend;
    } finally {
      _writing = false;
    }
  }

  Future<Blend> revise(
    String blendId,
    List<Ingredient> ingredients, {
    String notes = '',
  }) async {
    if (_writing) throw StateError('Write already in progress');
    _writing = true;
    try {
      final index = _blends.indexWhere((b) => b.id == blendId);
      if (index < 0) throw StateError('Blend not found');
      final prior = _blends[index];
      final updated = Blend(
        id: prior.id,
        name: prior.name,
        revisions: [
          ...prior.revisions,
          Revision(
            id: _id(),
            createdAt: DateTime.now().toUtc(),
            ingredients: ingredients,
            notes: notes,
          ),
        ],
      );
      final next = [..._blends];
      next[index] = updated;
      await _save(next);
      return updated;
    } finally {
      _writing = false;
    }
  }

  Future<void> _save(List<Blend> next) async {
    final temp = File('${file.path}.pending');
    final backup = File('${file.path}.previous');
    await file.parent.create(recursive: true);
    try {
      await temp.writeAsString(
        jsonEncode({
          'schemaVersion': 2,
          'blends': next.map((b) => b.toJson()).toList(),
        }),
        flush: true,
      );
      if (await file.exists()) {
        await file.copy(backup.path);
      }
      await temp.rename(file.path);
      _blends = next;
      if (await backup.exists()) {
        await backup.delete();
      }
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }
}
