import 'package:flutter/material.dart';

/// The vocabulary of icon tokens we store in `subjects.icon`, and the
/// Material icons we render them as. Shared between [SubjectCard] and the
/// edit screen's icon picker so they stay in sync.
class SubjectIcons {
  SubjectIcons._();

  /// All selectable tokens, in display order.
  static const tokens = <String>['pets', 'plant', 'home', 'shopping', 'bins'];

  static IconData iconFor(String? token) {
    switch (token) {
      case 'pets':
        return Icons.pets;
      case 'plant':
        return Icons.eco;
      case 'home':
        return Icons.home_outlined;
      case 'shopping':
        return Icons.shopping_cart_outlined;
      case 'bins':
        return Icons.delete_outline;
      default:
        return Icons.task_alt;
    }
  }
}
