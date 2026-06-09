import 'package:flutter/material.dart';

import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';

/// Horizontal scrolling row of character avatars. The selected one is
/// highlighted with a primary border and primary-container background.
///
/// Pass [selected] (nullable so "nothing chosen yet" is a valid state),
/// receive a non-null character id via [onChanged].
class CharacterPicker extends StatelessWidget {
  /// Currently-selected character id. Null = nothing selected (e.g.
  /// brand-new subject the user hasn't picked for yet).
  final String? selected;

  final ValueChanged<String> onChanged;

  const CharacterPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: CharacterRegistry.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = CharacterRegistry.all[i];
          return _Tile(
            character: c,
            isSelected: c.id == selected,
            onTap: () => onChanged(c.id),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tile({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer
                  : character.stageColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: CharacterArtwork(
              character: character,
              stage: false,
              iconSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            character.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
