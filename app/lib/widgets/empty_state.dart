import 'package:flutter/material.dart';

import '../core/subjects/character.dart';
import '../core/subjects/character_artwork.dart';

/// Generic empty-state panel.
///
/// Pass either a [Material icon][icon] *or* a [character] to use as the
/// hero glyph - the character variant pairs the artwork with its stage
/// colour for a friendlier surface (used on home, Subjects, History, etc).
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Character? character;
  final String title;
  final String? message;
  final String? actionLabel;

  /// Optional glyph on the action button (e.g. the paw on "Add a thing").
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.character,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  }) : assert(
         icon != null || character != null,
         'EmptyState needs either an icon or a character',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (character != null)
              SizedBox(
                width: 140,
                height: 140,
                child: ClipOval(
                  child: CharacterArtwork(
                    character: character!,
                    stage: true,
                    iconSize: 72,
                  ),
                ),
              )
            else
              Icon(icon!, size: 56, color: theme.hintColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              if (actionIcon != null)
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel!),
                )
              else
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
