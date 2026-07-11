import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../chores/chore.dart';
import '../chores/chores_controller.dart';
import '../subjects/subject.dart';
import '../subjects/subjects_controller.dart';
import 'completion.dart';
import 'household_history_controller.dart';
import 'stats_controller.dart';

part 'awards_controller.g.dart';

/// One per-member weekly award - Early Bird, Night Owl, etc. A null
/// [winnerUserId] means nobody qualified this week (no matching
/// completions, or a tie for first).
///
/// Carries no display strings - the widget layer maps [id] to its localized
/// title/description/emoji (see `awards_section.dart`), keeping this
/// provider's output pure, locale-independent data.
class MemberAward {
  /// Stable slug, e.g. `early_bird` - the key the widget layer localizes by.
  final String id;

  final String? winnerUserId;

  /// The winning tally (count for most awards, the improvement delta for
  /// Comeback Kid). Meaningless when [winnerUserId] is null.
  final int value;

  /// Badge artwork - filenames track the award ids.
  String get assetPath => 'assets/awards/badge_$id.png';

  const MemberAward({
    required this.id,
    required this.winnerUserId,
    required this.value,
  });
}

/// An award handed out by one of the household's own subjects, in its
/// character's voice - "Kiko's Best Human". Winner is whoever completed
/// the most of that subject's chores this week.
///
/// The award title + thank-you line are resolved at the widget layer
/// (pack `messages` override → localized bundled voice), not here.
class CharacterAward {
  final String subjectId;
  final String subjectName;

  /// Character id (drives the artwork + the title flavour).
  final String characterId;

  final String? winnerUserId;
  final int count;

  const CharacterAward({
    required this.subjectId,
    required this.subjectName,
    required this.characterId,
    required this.winnerUserId,
    required this.count,
  });
}

/// Everything the Awards tab can hand out for the current Mon→Sun week.
/// All derived from the cached household history (last 100 completions) -
/// no extra fetches.
class WeeklyAwards {
  final List<MemberAward> memberAwards;
  final List<CharacterAward> characterAwards;

  /// Days so far this week where every due chore in the household was
  /// completed.
  final int cleanSweeps;

  /// All seven days swept - only attainable from Sunday evening.
  final bool perfectWeek;

  /// Nobody did much more than their fair share - the busiest contributor
  /// stayed within 1.5x an even split (needs ≥2 contributors and a
  /// meaningful number of completions).
  final bool teamEffort;

  /// Everyone who logged at least one completion this week, busiest
  /// first. The Team Effort badge shows these when [teamEffort] is true.
  final List<String> contributorIds;

  const WeeklyAwards({
    required this.memberAwards,
    required this.characterAwards,
    required this.cleanSweeps,
    required this.perfectWeek,
    required this.teamEffort,
    required this.contributorIds,
  });

  static const empty = WeeklyAwards(
    memberAwards: [],
    characterAwards: [],
    cleanSweeps: 0,
    perfectWeek: false,
    teamEffort: false,
    contributorIds: [],
  );
}

@riverpod
WeeklyAwards weeklyAwards(Ref ref) {
  final history =
      ref.watch(householdHistoryControllerProvider).valueOrNull ??
      const <Completion>[];
  final chores =
      ref.watch(choresControllerProvider).valueOrNull ?? const <Chore>[];
  final subjects =
      ref.watch(subjectsControllerProvider).valueOrNull ?? const <Subject>[];
  if (history.isEmpty) return WeeklyAwards.empty;

  final window = WeekWindow.current();
  final thisWeek = [
    for (final c in history)
      if (!c.completedAt.isBefore(window.start) &&
          c.completedAt.isBefore(window.end))
        c,
  ];
  final prevWindow = window.previous();
  final lastWeek = [
    for (final c in history)
      if (!c.completedAt.isBefore(prevWindow.start) &&
          c.completedAt.isBefore(prevWindow.end))
        c,
  ];

  final choreById = <String, Chore>{for (final c in chores) c.id: c};

  // ---- Per-member personality awards -----------------------------------

  Map<String, int> tally(Iterable<Completion> list) {
    final out = <String, int>{};
    for (final c in list) {
      out.update(c.completedById, (v) => v + 1, ifAbsent: () => 1);
    }
    return out;
  }

  final memberAwards = <MemberAward>[
    // Comeback Kid leads - it renders second in the Badges grid, right
    // after the household-wide Team Effort card.
    _comebackKid(thisWeek: tally(thisWeek), lastWeek: tally(lastWeek)),
    _award(
      id: 'early_bird',
      tallies: tally(thisWeek.where((c) => c.completedAt.hour < 9)),
    ),
    _award(
      id: 'night_owl',
      tallies: tally(thisWeek.where((c) => c.completedAt.hour >= 20)),
    ),
    _award(
      id: 'on_the_dot',
      tallies: tally(
        thisWeek.where((c) {
          final chore = c.choreId == null ? null : choreById[c.choreId];
          if (chore == null) return false;
          final scheduled = chore.rule.scheduledAt(c.completedAt);
          return (c.completedAt.difference(scheduled)).abs() <=
              const Duration(minutes: 15);
        }),
      ),
    ),
    _award(
      id: 'weekend_warrior',
      tallies: tally(
        thisWeek.where(
          (c) =>
              c.completedAt.weekday == DateTime.saturday ||
              c.completedAt.weekday == DateTime.sunday,
        ),
      ),
    ),
    _award(
      id: 'tag_champion',
      tallies: tally(thisWeek.where((c) => c.source == CompletionSource.nfc)),
    ),
  ];

  // ---- Household-wide achievements --------------------------------------

  final cleanSweeps = _cleanSweepDays(
    window: window,
    chores: chores,
    thisWeek: thisWeek,
  );

  final weekTally = tally(thisWeek);
  final weekTotal = thisWeek.length;
  final contributorCount = weekTally.length;
  final maxShare = weekTally.isEmpty
      ? 0.0
      : weekTally.values.reduce((a, b) => a > b ? a : b) / weekTotal;
  // Team Effort scales with household size: nobody may do more than 1.5x an
  // even share (1 / contributors). A fixed 50% cap was unwinnable for two
  // people (it needed a perfect tie, impossible on odd weeks) and far too
  // lenient for big households (49% is one person carrying a five-way team).
  final teamEffort = weekTotal >= 5 &&
      contributorCount >= 2 &&
      maxShare <= 1.5 / contributorCount;
  final contributorIds =
      (weekTally.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => e.key)
          .toList();

  // ---- Character-voiced awards (one per subject) -------------------------
  //
  // Unlike the personality badges above, these lock to the last *settled*
  // award week (Sun→Sun, presented Sunday evening) so a character's "Best
  // Human" can't change hands mid-week - see WeekWindow.settledAward.

  final awardWindow = WeekWindow.settledAward();
  final awardWeek = [
    for (final c in history)
      if (!c.completedAt.isBefore(awardWindow.start) &&
          c.completedAt.isBefore(awardWindow.end))
        c,
  ];

  final characterAwards = <CharacterAward>[];
  for (final s in subjects) {
    final tallies = tally(awardWeek.where((c) => c.subjectId == s.id));
    final winner = _uniqueMax(tallies);
    characterAwards.add(
      CharacterAward(
        subjectId: s.id,
        subjectName: s.name,
        characterId: s.icon ?? 'generic',
        winnerUserId: winner?.userId,
        count: winner?.value ?? 0,
      ),
    );
  }
  // Carousel order: won awards first, then by winning tally (busiest
  // subject leads), then alphabetically so the order is stable.
  characterAwards.sort((a, b) {
    final wonCompare = (a.winnerUserId == null ? 1 : 0).compareTo(
      b.winnerUserId == null ? 1 : 0,
    );
    if (wonCompare != 0) return wonCompare;
    final countCompare = b.count.compareTo(a.count);
    if (countCompare != 0) return countCompare;
    return a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase());
  });

  return WeeklyAwards(
    memberAwards: memberAwards,
    characterAwards: characterAwards,
    cleanSweeps: cleanSweeps,
    perfectWeek: cleanSweeps == 7,
    teamEffort: teamEffort,
    contributorIds: contributorIds,
  );
}

/// Builds a [MemberAward] from per-user tallies. The winner must be a
/// **unique** maximum - ties hand out nothing (siblings would riot).
MemberAward _award({required String id, required Map<String, int> tallies}) {
  final winner = _uniqueMax(tallies);
  return MemberAward(
    id: id,
    winnerUserId: winner?.userId,
    value: winner?.value ?? 0,
  );
}

/// Comeback Kid - biggest improvement on your own last-week count. Only
/// positive deltas qualify; unique max wins.
MemberAward _comebackKid({
  required Map<String, int> thisWeek,
  required Map<String, int> lastWeek,
}) {
  final deltas = <String, int>{};
  for (final userId in {...thisWeek.keys, ...lastWeek.keys}) {
    final delta = (thisWeek[userId] ?? 0) - (lastWeek[userId] ?? 0);
    if (delta > 0) deltas[userId] = delta;
  }
  final winner = _uniqueMax(deltas);
  return MemberAward(
    id: 'comeback_kid',
    winnerUserId: winner?.userId,
    value: winner?.value ?? 0,
  );
}

/// Days from Monday up to today where every due chore in the household
/// has at least one completion logged that day. Days with nothing due
/// don't count as sweeps (an empty day isn't an achievement).
int _cleanSweepDays({
  required WeekWindow window,
  required List<Chore> chores,
  required List<Completion> thisWeek,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // choreId → set of local days it was completed on this week.
  final doneDays = <String, Set<DateTime>>{};
  for (final c in thisWeek) {
    final id = c.choreId;
    if (id == null) continue;
    final d = c.completedAt;
    doneDays.putIfAbsent(id, () => {}).add(DateTime(d.year, d.month, d.day));
  }

  var sweeps = 0;
  for (
    var day = window.start;
    !day.isAfter(today) && day.isBefore(window.end);
    day = day.add(const Duration(days: 1))
  ) {
    final due = [
      for (final c in chores)
        if (c.active && c.rule.isDueOn(day)) c,
    ];
    if (due.isEmpty) continue;
    final allDone = due.every((c) => doneDays[c.id]?.contains(day) ?? false);
    if (allDone) sweeps += 1;
  }
  return sweeps;
}

({String userId, int value})? _uniqueMax(Map<String, int> tallies) {
  String? bestUser;
  var best = 0;
  var tied = false;
  tallies.forEach((userId, value) {
    if (value > best) {
      best = value;
      bestUser = userId;
      tied = false;
    } else if (value == best && value > 0) {
      tied = true;
    }
  });
  if (bestUser == null || best == 0 || tied) return null;
  return (userId: bestUser!, value: best);
}
