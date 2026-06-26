import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore.dart';
import '../../core/chores/schedule_rule.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/completion_actions.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/stats_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/household/acting_user_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../completions/celebration_args.dart';
import '../profile/avatar_artwork.dart';
import 'undo_confirm_dialog.dart';

/// A wide, tappable row representing one chore for today on the subject
/// detail screen. Renders the chore name + schedule line; trailing shows
/// either the completed time + a green tick (when logged today) or the
/// scheduled time + an outlined circle (when still outstanding).
///
/// Same toggle-on-tap semantics as [ChoreChipWithTap]: tap an outstanding
/// row to log; tap a completed row (logged by you) to undo. Tapping a row
/// logged by someone else shows an explainer snackbar.
class ChoreRow extends ConsumerWidget {
  final Chore chore;
  final String subjectId;
  final Completion? existingCompletion;

  /// Optional widget to render in the leading (left) slot. When null,
  /// the row uses its default state-coloured avatar with a check / clock /
  /// error icon. Pass a custom one (e.g. a character portrait) on screens
  /// where each row should show *what* the chore is for rather than just
  /// its status.
  final Widget? leading;

  /// When set, tapping the leading slot fires this instead of toggling the
  /// chore - e.g. the home card's subject portrait opens the subject page.
  final VoidCallback? onLeadingTap;

  /// When set, tapping the trailing status slot fires this instead of toggling
  /// the chore - e.g. the home card's status opens the chore editor.
  final VoidCallback? onTrailingTap;

  const ChoreRow({
    super.key,
    required this.chore,
    required this.subjectId,
    required this.existingCompletion,
    this.leading,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  /// Wraps [child] in a tap target that swallows the gesture (so it doesn't
  /// reach the row's complete-on-tap InkWell) when [onTap] is set; otherwise
  /// returns [child] untouched.
  static Widget _tappable(VoidCallback? onTap, Widget child) {
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  Future<void> _log(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(completionActionsProvider)
          .logChore(
            subjectId: subjectId,
            choreId: chore.id,
            choreName: chore.name,
            source: CompletionSource.button,
          );

      // Wait for the post-log invalidation of the recent-completions list
      // to settle so the streak provider has the new completion in scope
      // before we read it.
      await ref.read(recentCompletionsControllerProvider(subjectId).future);
      final streak = ref.read(subjectStreakProvider(subjectId));

      // Show the celebration overlay. Look up the subject so we can pick
      // the right character (and the user's name for "logged by …").
      final subjects =
          ref.read(subjectsControllerProvider).valueOrNull ?? const [];
      String? iconToken;
      for (final s in subjects) {
        if (s.id == subjectId) {
          iconToken = s.icon;
          break;
        }
      }
      final character = ref.read(catalogProvider).lookupCharacter(iconToken);
      // Names whoever the completion was logged *as* (the "Act as" identity).
      final actingMember = await ref.read(actingMemberProvider.future);

      if (!context.mounted) return;
      context.push(
        Routes.celebration,
        extra: CelebrationArgs(
          character: character,
          choreName: chore.name,
          whoName: actingMember?.displayName,
          whoAvatar: actingMember?.avatar,
          streak: streak,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not log: $e')),
      );
    }
  }

  Future<void> _undo(
    BuildContext context,
    WidgetRef ref,
    Completion completion,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Undo allowed for whoever logged it (including while acting as that
    // member) or the household owner - mirrors the server delete rule.
    final actingUserId = ref.read(actingUserControllerProvider).valueOrNull;
    final isOwner =
        ref.read(currentHouseholdControllerProvider).valueOrNull?.isOwner ??
        false;
    if (completion.completedById != actingUserId && !isOwner) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Switch to whoever logged this (or ask an owner) to undo it.',
          ),
        ),
      );
      return;
    }
    if (!await confirmUndoCompletion(context, chore.name)) return;
    try {
      await ref.read(completionActionsProvider).undo(completion.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Removed: ${chore.name}')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not undo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completion = existingCompletion;
    final isDone = completion != null;

    final now = DateTime.now();
    final scheduledToday = chore.rule.scheduledAt(now);
    final isOverdue = !isDone && scheduledToday.isBefore(now);
    final dueIn = !isDone && !isOverdue ? scheduledToday.difference(now) : null;
    final isDueSoon = dueIn != null && dueIn <= const Duration(hours: 1);

    final scheduleLine = isOverdue
        ? _formatOverdue(now.difference(scheduledToday))
        : chore.rule.humanLabel();

    // "Usually around 7:05 AM" - the household's habit for this chore,
    // from the mean of past completion times.
    final meanTime = ref.watch(choreMeanTimesProvider)[chore.id];

    final cardColor = isDone
        ? Colors.green.shade50
        : isOverdue
        ? Colors.red.shade50
        : scheme.surfaceContainer;
    final avatarBg = isDone
        ? Colors.green.shade100
        : isOverdue
        ? Colors.red.shade100
        : scheme.surfaceContainerHighest;
    final avatarFg = isDone
        ? Colors.green.shade900
        : isOverdue
        ? Colors.red.shade900
        : scheme.onSurfaceVariant;
    final titleColor = isDone
        ? Colors.green.shade900
        : isOverdue
        ? Colors.red.shade900
        : null;
    final subLineColor = isDone
        ? Colors.green.shade700
        : isOverdue
        ? Colors.red.shade700
        : scheme.onSurfaceVariant;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        // Plain (not-yet-due) cards get a soft warm stroke so the white
        // separates from the cream backdrop; the green/red tinted states
        // keep the white border that makes the pastels read.
        side: isDone || isOverdue
            ? BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              )
            : BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            isDone ? _undo(context, ref, completion) : _log(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _tappable(
                    onLeadingTap,
                    leading ??
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: avatarBg,
                          foregroundColor: avatarFg,
                          child: Icon(
                            isDone
                                ? Icons.check
                                : isOverdue
                                ? Icons.error_outline
                                : chore.isOnce
                                ? Icons.event
                                : Icons.schedule,
                            size: 22,
                          ),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                chore.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            if (chore.isOnce) ...[
                              const SizedBox(width: 8),
                              const _OnceBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scheduleLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subLineColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tappable(
                    onTrailingTap,
                    _TrailingStatus(
                      isDone: isDone,
                      isOverdue: isOverdue,
                      isDueSoon: isDueSoon,
                      dueIn: dueIn,
                      isOnce: chore.isOnce,
                    ),
                  ),
                ],
              ),
              if (isDone) ...[
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.green.shade100),
                const SizedBox(height: 10),
                _CompletedByRow(completion: completion),
              ] else if (meanTime != null) ...[
                // Same footer slot the completed-by row occupies, but
                // showing the household's habit time while outstanding.
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: Icon(
                          Icons.history,
                          size: 18,
                          color: subLineColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Usually done around',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subLineColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ScheduleRule.formatClock(meanTime.hour, meanTime.minute),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subLineColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "One-time" pill marking a one-off chore on a [ChoreRow]. Primary
/// tint so it reads on the neutral, green (done) and red (overdue) card states
/// alike without competing with them.
class _OnceBadge extends StatelessWidget {
  const _OnceBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'One-time',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "5 minutes overdue", "1 minute overdue", "1 hour overdue",
/// "over 3 hours overdue".
String _formatOverdue(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 60) {
    return minutes == 1 ? '1 minute overdue' : '$minutes minutes overdue';
  }
  final hours = d.inHours;
  if (hours == 1) return '1 hour overdue';
  return 'over $hours hours overdue';
}

/// Trailing cell on a [ChoreRow]. Shows either:
///   - "Due in / N / mins|hrs" stacked, in amber (when due in ≤2h)
///   - The completed-at time in green (when done)
///   - The scheduled time (everything else)
class _TrailingStatus extends StatelessWidget {
  final bool isDone;
  final bool isOverdue;
  final bool isDueSoon;
  final Duration? dueIn;
  final bool isOnce;

  const _TrailingStatus({
    required this.isDone,
    required this.isOverdue,
    required this.isDueSoon,
    required this.dueIn,
    required this.isOnce,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Done - green tick.
    if (isDone) {
      return Icon(Icons.check_circle, size: 28, color: Colors.green.shade700);
    }

    // Overdue - red warning icon. The schedule line below already reads
    // "X minutes overdue" so we don't need to repeat the number here.
    if (isOverdue) {
      return Icon(Icons.error_outline, size: 28, color: Colors.red.shade700);
    }

    // Due within the hour - "Due in N mins/hr" stack.
    if (isDueSoon && dueIn != null) {
      final m = dueIn!.inMinutes;
      final showHours = m >= 60;
      final value = showHours ? dueIn!.inHours : m;
      final unit = showHours
          ? (value == 1 ? 'hour' : 'hrs')
          : (value == 1 ? 'min' : 'mins');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Due in',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            unit,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Anything later than an hour away - neutral clock, or a calendar glyph
    // for a one-off (it's a dated task, not a recurring time).
    return Icon(
      isOnce ? Icons.event : Icons.schedule,
      size: 28,
      color: scheme.onSurfaceVariant,
    );
  }
}

/// Bottom row of a completed [ChoreRow] - small member avatar, name,
/// completion timestamp.
class _CompletedByRow extends ConsumerWidget {
  final Completion completion;

  const _CompletedByRow({required this.completion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final members = hh == null
        ? const <HouseholdMember>[]
        : ref.watch(householdMembersControllerProvider(hh.id)).valueOrNull ??
              const <HouseholdMember>[];

    HouseholdMember? me;
    for (final m in members) {
      if (m.userId == completion.completedById) {
        me = m;
        break;
      }
    }
    final name = me?.displayName ?? 'Someone';
    final avatar = ref.watch(catalogProvider).lookupAvatar(me?.avatar);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final seed = me?.userId ?? completion.completedById;
    final bg = _colorFromSeed(seed);
    final fg = _readableOn(bg);

    return Row(
      children: [
        // 44-wide lane mirrors the top row's avatar diameter so the small
        // avatar centres on the same vertical axis as the big one above.
        SizedBox(
          width: 44,
          child: Center(
            child: avatar != null
                ? AvatarArtwork(avatar: avatar, size: 24)
                : CircleAvatar(
                    radius: 12,
                    backgroundColor: bg,
                    foregroundColor: fg,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Completed by $name',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade900,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ScheduleRule.formatClock(
            completion.completedAt.hour,
            completion.completedAt.minute,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Same stable-from-seed colour helpers as HouseholdMembersRow - extracted
  // here too rather than imported because the row is private to that file.
  Color _colorFromSeed(String seed) {
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.72).toColor();
  }

  Color _readableOn(Color bg) {
    final hsl = HSLColor.fromColor(bg);
    return hsl.lightness > 0.6 ? Colors.black87 : Colors.white;
  }
}
