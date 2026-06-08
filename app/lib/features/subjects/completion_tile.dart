import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';

/// One row in the history list — who logged what, when, via which input
/// (button / nfc / manual). Looks up the chore + user from cached providers
/// so the tile doesn't have to fetch anything itself.
class CompletionTile extends ConsumerWidget {
  final Completion completion;
  final String householdId;

  const CompletionTile({
    super.key,
    required this.completion,
    required this.householdId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chores = ref.watch(choresControllerProvider).valueOrNull ?? const [];
    final members = ref
            .watch(householdMembersControllerProvider(householdId))
            .valueOrNull ??
        const [];
    final myUserId = ref.watch(authControllerProvider).valueOrNull?.userId;

    Chore? chore;
    for (final c in chores) {
      if (c.id == completion.choreId) {
        chore = c;
        break;
      }
    }
    HouseholdMember? user;
    for (final m in members) {
      if (m.userId == completion.completedById) {
        user = m;
        break;
      }
    }

    final whoName = user == null
        ? 'Someone'
        : (user.userId == myUserId ? 'You' : user.displayName);
    final whatName = chore?.name ?? 'Logged';

    final loc = MaterialLocalizations.of(context);
    final dateStr = loc.formatShortDate(completion.completedAt);
    final timeStr =
        TimeOfDay.fromDateTime(completion.completedAt).format(context);

    return ListTile(
      dense: true,
      leading: Icon(_iconForSource(completion.source), size: 20),
      title: Text(whatName),
      subtitle: Text('$whoName · $dateStr at $timeStr'),
    );
  }

  IconData _iconForSource(CompletionSource source) {
    switch (source) {
      case CompletionSource.nfc:
        return Icons.nfc;
      case CompletionSource.manual:
        return Icons.edit_note;
      case CompletionSource.button:
        return Icons.touch_app_outlined;
    }
  }
}
