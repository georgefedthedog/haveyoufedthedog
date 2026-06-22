import 'package:flutter/material.dart';

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
      title: const Text("You're already signed in"),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Claim links set up a brand-new sign-in for a member someone "
              "created for you. They can't be added to an account you're "
              "already signed in to - we don't merge accounts.",
            ),
            SizedBox(height: 14),
            Text('If this code is for you:'),
            SizedBox(height: 10),
            Text(
              "• Keep this account - stay signed in as you, and ask whoever "
              "sent the link for a household join link instead.",
            ),
            SizedBox(height: 8),
            Text(
              "• Become that member - delete this account, then the claim "
              "opens automatically. Your completed chores stay with the "
              "household.",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep my account'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete account & claim'),
        ),
      ],
    ),
  );
  return result ?? false;
}
