import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/time_of_day_bucket.dart';
import '../chores/chores_controller.dart';
import '../completions/today_completions_controller.dart';
import 'character.dart';
import 'character_message.dart';

part 'subject_mood_controller.g.dart';

/// How [subjectId] is doing right now — see [SubjectMood] for the
/// priority order. Derived from the chores + today-completions
/// controllers; no extra fetch. Watch this anywhere a subject's state
/// drives UI (hero expression, status copy, card art).
@riverpod
SubjectMood subjectMood(Ref ref, String subjectId) {
  final allChores =
      ref.watch(choresControllerProvider).valueOrNull ?? const [];
  final completions =
      ref.watch(todayCompletionsControllerProvider).valueOrNull ?? const [];

  final now = DateTime.now();
  final dueToday = allChores
      .where((c) => c.subjectId == subjectId && c.rule.isDueOn(now))
      .toList();
  if (dueToday.isEmpty) return SubjectMood.none;

  final doneIds = <String>{
    for (final c in completions)
      if (c.choreId != null) c.choreId!,
  };
  final unlogged = dueToday.where((c) => !doneIds.contains(c.id)).toList();
  if (unlogged.isEmpty) return SubjectMood.allDone;

  if (unlogged.any((c) => c.rule.scheduledAt(now).isBefore(now))) {
    return SubjectMood.overdue;
  }

  const window = Duration(hours: 1);
  if (unlogged.any((c) {
    final at = c.rule.scheduledAt(now);
    final diff = at.difference(now);
    return !diff.isNegative && diff <= window;
  })) {
    return SubjectMood.upcoming;
  }

  return SubjectMood.happyForNow;
}

/// Single source of truth for which face a mood wears, so every surface
/// (detail hero, cards, future read-sites) agrees.
extension SubjectMoodExpression on SubjectMood {
  CharacterExpression get expression {
    // Everything done and it's night (after 20:00) — tucked in for the
    // day rather than grinning into the dark.
    if (this == SubjectMood.allDone &&
        bucketFor(DateTime.now()) == TimeOfDayBucket.night) {
      return CharacterExpression.sleeping;
    }
    return switch (this) {
      SubjectMood.allDone => CharacterExpression.happy,
      SubjectMood.overdue => CharacterExpression.sad,
      SubjectMood.upcoming => CharacterExpression.idle,
      SubjectMood.happyForNow => CharacterExpression.idle,
      // Day off — nothing due today, let them snooze.
      SubjectMood.none => CharacterExpression.sleeping,
    };
  }
}
