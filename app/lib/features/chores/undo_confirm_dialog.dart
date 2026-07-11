import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

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
      title: Text(ctx.l10n.undoDialogTitle(choreName)),
      content: Text(ctx.l10n.undoDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.undoDialogAction),
        ),
      ],
    ),
  );
  return result ?? false;
}
