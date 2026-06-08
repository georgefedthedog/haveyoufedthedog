import 'package:flutter/material.dart';

import '../../core/subjects/subject_icons.dart';

/// Grid of selectable subject icons. Each tile is a circular avatar; the
/// selected one is highlighted with the primary container colour.
///
/// [selected] may be `null` (no icon yet). Tapping the currently-selected
/// tile clears the selection — handy for "I changed my mind, no icon."
class IconPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const IconPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final token in SubjectIcons.tokens)
          _Tile(
            token: token,
            isSelected: token == selected,
            scheme: scheme,
            onTap: () => onChanged(token == selected ? null : token),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String token;
  final bool isSelected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _Tile({
    required this.token,
    required this.isSelected,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: scheme.primary, width: 2)
              : null,
        ),
        child: Icon(
          SubjectIcons.iconFor(token),
          color: isSelected
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
