import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/chores/schedule_labels.dart';
import '../../core/completions/completion.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../l10n/l10n.dart';

/// Completions as a day-grouped vertical timeline: "Today / Yesterday /
/// Monday 9 June" headers, a time + node + connecting line gutter, and a
/// card per entry showing the subject's character, the chore, who logged
/// it, and how (NFC tap vs in-app).
///
/// Pass the completions newest-first (both feeding controllers already
/// sort `-completed_at`).
class CompletionTimeline extends ConsumerWidget {
  final List<Completion> completions;
  final String householdId;

  const CompletionTimeline({
    super.key,
    required this.completions,
    required this.householdId,
  });

  /// "Today" / "Yesterday" / "Monday 9 June" (locale-formatted).
  String _dayLabel(AppLocalizations l10n, DateTime day, DateTime today) {
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return l10n.commonToday;
    if (diff == 1) return l10n.commonYesterday;
    return DateFormat('EEEE d MMMM', l10n.localeName).format(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chores =
        ref.watch(choresControllerProvider).valueOrNull ?? const <Chore>[];
    final subjects =
        ref.watch(subjectsControllerProvider).valueOrNull ?? const <Subject>[];
    final members =
        ref
            .watch(householdMembersControllerProvider(householdId))
            .valueOrNull ??
        const <HouseholdMember>[];
    final myUserId = ref.watch(authControllerProvider).valueOrNull?.userId;

    final choreById = <String, Chore>{for (final c in chores) c.id: c};
    final subjectById = <String, Subject>{for (final s in subjects) s.id: s};
    final memberById = <String, HouseholdMember>{
      for (final m in members) m.userId: m,
    };

    // Group into day buckets, preserving the newest-first order.
    final now = DateTime.now();
    final groups = <DateTime, List<Completion>>{};
    for (final c in completions) {
      final d = c.completedAt;
      groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _dayLabel(context.l10n, entry.key, now),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < entry.value.length; i++)
                      _TimelineRow(
                        completion: entry.value[i],
                        isFirstInGroup: i == 0,
                        isLastInGroup: i == entry.value.length - 1,
                        chore: entry.value[i].choreId == null
                            ? null
                            : choreById[entry.value[i].choreId],
                        subject: subjectById[entry.value[i].subjectId],
                        member: memberById[entry.value[i].completedById],
                        isMe: entry.value[i].completedById == myUserId,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  final Completion completion;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final Chore? chore;
  final Subject? subject;
  final HouseholdMember? member;
  final bool isMe;

  const _TimelineRow({
    required this.completion,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.chore,
    required this.subject,
    required this.member,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final character = ref.watch(catalogProvider).lookupCharacter(subject?.icon);
    final time = formatClock(
      completion.completedAt.hour,
      completion.completedAt.minute,
      context.l10n.localeName,
    );
    final who = isMe
        ? context.l10n.commonYou
        : (member?.displayName ?? context.l10n.commonSomeone);

    // Chore + who + source, hugging the spine: right-aligned when it
    // sits on the left, left-aligned when on the right.
    final details = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          // Prefer the live chore name (so a rename shows retroactively),
          // fall back to the name stored on the completion when the chore is
          // gone, then a neutral last resort.
          chore?.name ?? completion.choreName ?? context.l10n.timelineLogged,
          overflow: TextOverflow.ellipsis,
          textAlign: isMe ? TextAlign.left : TextAlign.right,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          // Icon hugs the outer edge: before the name on the left side,
          // after it on the right.
          children: [
            if (!isMe) ...[
              Icon(
                completion.source == CompletionSource.nfc
                    ? Icons.nfc
                    : Icons.touch_app_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              who,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                completion.source == CompletionSource.nfc
                    ? Icons.nfc
                    : Icons.touch_app_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left half - other people's completions live here.
          Expanded(
            child: isMe
                ? const SizedBox.shrink()
                : Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 14),
                    child: details,
                  ),
          ),
          // The spine: character node with the time beneath it, line
          // segments running out the top and bottom - skipped at a
          // group's first/last so neighbouring rows meet seamlessly.
          SizedBox(
            width: 56,
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                  child: isFirstInGroup
                      ? null
                      : Container(width: 3.5, color: scheme.outlineVariant),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CharacterArtwork(
                    character: character,
                    stage: false,
                    iconSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(
                  height: 10,
                  child: isLastInGroup
                      ? null
                      : Container(width: 3.5, color: scheme.outlineVariant),
                ),
              ],
            ),
          ),
          // Right half - the signed-in user's completions live here.
          Expanded(
            child: !isMe
                ? const SizedBox.shrink()
                : Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 14),
                    child: details,
                  ),
          ),
        ],
      ),
    );
  }
}
