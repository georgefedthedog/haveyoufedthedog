import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'household_history_controller.dart';

part 'stats_controller.g.dart';

/// Weekly window for stats — Monday→Sunday based on the user's local clock.
class WeekWindow {
  final DateTime start; // inclusive, at 00:00 local
  final DateTime end; // exclusive, at next-Monday 00:00 local
  const WeekWindow(this.start, this.end);

  static WeekWindow current() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // DateTime.weekday: Mon = 1, Sun = 7. Snap back to Monday.
    final mondayOffset = today.weekday - DateTime.monday;
    final start = today.subtract(Duration(days: mondayOffset));
    final end = start.add(const Duration(days: 7));
    return WeekWindow(start, end);
  }

  WeekWindow previous() {
    return WeekWindow(
      start.subtract(const Duration(days: 7)),
      start,
    );
  }
}

class WeeklyStats {
  /// Total completions in the window, across the whole household.
  final int total;

  /// Per-user completion count, ordered descending (winner first).
  /// Map preserves insertion order in Dart.
  final Map<String, int> perUser;

  const WeeklyStats({required this.total, required this.perUser});

  static const empty = WeeklyStats(total: 0, perUser: {});
}

/// Stats for the current ISO week (Mon → Sun, local clock). Derived from
/// [householdHistoryControllerProvider]; no extra fetch.
@riverpod
WeeklyStats currentWeekStats(Ref ref) {
  final list = ref
          .watch(householdHistoryControllerProvider)
          .valueOrNull ??
      const [];
  return _windowStats(list, WeekWindow.current());
}

/// Stats for last week — used for the week-over-week delta on the History
/// tab. Same data source.
@riverpod
WeeklyStats previousWeekStats(Ref ref) {
  final list = ref
          .watch(householdHistoryControllerProvider)
          .valueOrNull ??
      const [];
  return _windowStats(list, WeekWindow.current().previous());
}

WeeklyStats _windowStats(List list, WeekWindow window) {
  final perUser = <String, int>{};
  var total = 0;
  for (final c in list) {
    final at = c.completedAt;
    if (at.isBefore(window.start) || !at.isBefore(window.end)) continue;
    total += 1;
    perUser.update(c.completedById, (v) => v + 1, ifAbsent: () => 1);
  }
  // Sort descending by count for the leaderboard render.
  final sorted = perUser.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return WeeklyStats(
    total: total,
    perUser: {for (final e in sorted) e.key: e.value},
  );
}

/// Number of consecutive days (ending today or yesterday) the household has
/// had at least one completion across any subject. Mirror of
/// `subjectStreakProvider` but aggregated.
@riverpod
int householdStreak(Ref ref) {
  final list = ref
          .watch(householdHistoryControllerProvider)
          .valueOrNull ??
      const [];
  if (list.isEmpty) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final dayKeys = <DateTime>{};
  for (final c in list) {
    final d = c.completedAt;
    dayKeys.add(DateTime(d.year, d.month, d.day));
  }
  final sortedDays = dayKeys.toList()..sort((a, b) => b.compareTo(a));

  final latest = sortedDays.first;
  if (today.difference(latest).inDays > 1) return 0;

  var streak = 1;
  var prev = latest;
  for (final d in sortedDays.skip(1)) {
    final expected = prev.subtract(const Duration(days: 1));
    if (d.year == expected.year &&
        d.month == expected.month &&
        d.day == expected.day) {
      streak += 1;
      prev = d;
    } else {
      break;
    }
  }
  return streak;
}
