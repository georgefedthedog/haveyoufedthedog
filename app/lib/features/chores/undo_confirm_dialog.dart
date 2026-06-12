import 'package:flutter/material.dart';

/// Confirm before un-logging a completion - completed rows and chips sit
/// right where thumbs scroll, so accidental taps are easy. Same dialog
/// shape as the other destructive confirms (error/onError action button).
Future<bool> confirmUndoCompletion(
  BuildContext context,
  String choreName,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Undo "$choreName"?'),
      content: const Text(
        'This marks the chore as not done again, and the rest of the '
        'household is told.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Undo it'),
        ),
      ],
    ),
  );
  return result ?? false;
}
