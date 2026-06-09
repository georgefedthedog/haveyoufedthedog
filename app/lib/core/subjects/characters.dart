import 'package:flutter/material.dart';

import 'character.dart';

/// Curated registry of characters a subject can be drawn as. Each entry's
/// [Character.id] is what gets stored on `subjects.icon`.
///
/// Phase A ships only idle expressions — every entry declares only
/// [CharacterExpression.idle] in [Character.available]. As polished art
/// lands, expand the set so the celebration overlay (Phase B) and the
/// status-message engine can pick happier / unimpressed variants.
class CharacterRegistry {
  CharacterRegistry._();

  /// Ordered list — picker renders them in this order.
  static const all = <Character>[
    dog,
    cat,
    plant,
    bin,
    fish,
    child,
    generic,
  ];

  static const dog = Character(
    id: 'dog',
    displayName: 'Dog',
    stageColor: CharacterStage.dog,
    fallbackIcon: Icons.pets,
  );
  static const cat = Character(
    id: 'cat',
    displayName: 'Cat',
    stageColor: CharacterStage.cat,
    fallbackIcon: Icons.cruelty_free,
  );
  static const plant = Character(
    id: 'plant',
    displayName: 'Plant',
    stageColor: CharacterStage.plant,
    fallbackIcon: Icons.eco,
  );
  static const bin = Character(
    id: 'bin',
    displayName: 'Wheelie bin',
    stageColor: CharacterStage.bin,
    fallbackIcon: Icons.delete_outline,
  );
  static const fish = Character(
    id: 'fish',
    displayName: 'Fish',
    stageColor: CharacterStage.fish,
    fallbackIcon: Icons.set_meal_outlined,
  );
  static const child = Character(
    id: 'child',
    displayName: 'Kid',
    stageColor: CharacterStage.child,
    fallbackIcon: Icons.child_care_outlined,
  );
  static const generic = Character(
    id: 'generic',
    displayName: 'Other',
    stageColor: CharacterStage.generic,
    fallbackIcon: Icons.task_alt,
  );

  /// Look up a character by stored [id]. Falls back to [generic] if the
  /// value is null, empty, or a legacy token from before the redesign
  /// (e.g. `pets`, `eco`, `shopping_cart`). The fallback also maps a few
  /// well-known legacy tokens to their closest character so existing data
  /// doesn't regress to the generic paw print.
  static Character lookup(String? id) {
    if (id == null || id.isEmpty) return generic;
    for (final c in all) {
      if (c.id == id) return c;
    }
    switch (id) {
      case 'pets':
        return dog;
      case 'eco':
      case 'plant_token':
        return plant;
      case 'delete':
      case 'bins':
        return bin;
      case 'shopping_cart':
      case 'shopping':
        return generic;
      case 'home':
        return generic;
      default:
        return generic;
    }
  }
}
