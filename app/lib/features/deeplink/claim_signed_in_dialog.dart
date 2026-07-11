import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Shown when a signed-in user taps a *claim* link. Claiming is a fresh
/// sign-up that takes over a managed member, so it can't be applied to an
/// account you're already in (we don't merge accounts). This explains the two
/// real choices and returns `true` if the user wants to delete this account
/// and claim, `false` (or dismiss) to keep their account.
Future<bool> showClaimWhileSignedInDialog(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.claimSignedInTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.l10n.claimSignedInBody),
            const SizedBox(height: 14),
            Text(ctx.l10n.claimSignedInIfForYou),
            const SizedBox(height: 10),
            Text(ctx.l10n.claimSignedInKeepOption),
            const SizedBox(height: 8),
            Text(ctx.l10n.claimSignedInBecomeOption),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.claimKeepAccount),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.claimDeleteAndClaim),
        ),
      ],
    ),
  );
  return result ?? false;
}
