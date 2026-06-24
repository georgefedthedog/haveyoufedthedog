import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../chores/chore.dart';
import '../chores/chores_controller.dart';
import '../household/current_household_controller.dart';

part 'reward_streak_controller.g.dart';

/// Approximate household-wide reward streak for the streak-unlock progress UI:
/// consecutive **due-days** (any active chore for any subject in the current
/// household) with at least one completion, counting only days *after* the
/// household's last free redemption. Lenient on purpose - the household just
/// has to log *something* on each due day.
///
/// This is **advisory**: the worker recomputes the streak authoritatively
/// (timezone-aware) when a claim is made, so this device-local copy only
/// drives the progress bar and the "claim" affordance. A day-boundary
/// difference at worst shows the claim button an hour early or late.
///
/// Unlike most stats it does its own small fetch rather than reuse the
/// last-100 [householdHistoryControllerProvider] cache: a long streak needs
/// more day-level history than 100 completions covers for a busy household.
/// We pull only the recent window (sorted newest-first, capped at one page),
/// which is the slice the backward walk actually reads.
@riverpod
Future<int> householdRewardStreak(Ref ref) async {
  final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;
  if (household == null) return 0;

  final allChores =
      ref.watch(choresControllerProvider).valueOrNull ?? const <Chore>[];
  final activeChores = [
    for (final c in allChores)
      if (c.active) c,
  ];
  if (activeChores.isEmpty) return 0;

  final pb = await ref.watch(pocketbaseClientProvider.future);

  // Bound the scan to a recent window (generous vs any sane threshold). PB
  // caps perPage at 500; the most-recent 500 within the window is the working
  // set for a backward walk from today.
  final since = DateTime.now().toUtc().subtract(const Duration(days: 200));
  final sinceLit = since.toIso8601String().replaceFirst('T', ' ');
  final result = await pb
      .collection('completions')
      .getList(
        page: 1,
        perPage: 500,
        filter: 'subject.household = "${household.id}" && completed_at >= "$sinceLit"',
        sort: '-completed_at',
      );

  final completedDays = <DateTime>{};
  DateTime? earliest;
  for (final r in result.items) {
    final raw = r.data['completed_at'] as String?;
    if (raw == null) continue;
    final d = DateTime.parse(raw).toLocal();
    final day = DateTime(d.year, d.month, d.day);
    completedDays.add(day);
    if (earliest == null || day.isBefore(earliest)) earliest = day;
  }
  if (earliest == null) return 0;

  final anchor = household.lastFreeRedemption?.toLocal();
  final anchorDay =
      anchor == null ? null : DateTime(anchor.year, anchor.month, anchor.day);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var streak = 0;
  for (var offset = 0; offset <= 366; offset++) {
    final day = today.subtract(Duration(days: offset));
    if (day.isBefore(earliest)) break;
    // Count only days strictly after the last redemption anchor.
    if (anchorDay != null && !day.isAfter(anchorDay)) break;

    final isDueDay = activeChores.any((c) => c.rule.isDueOn(day));
    if (!isDueDay) continue;

    if (completedDays.contains(day)) {
      streak += 1;
    } else if (offset == 0) {
      continue; // grace: today's outstanding chore doesn't break a carried run
    } else {
      break;
    }
  }
  return streak;
}
