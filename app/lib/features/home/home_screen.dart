import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/household/pictures.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/empty_state.dart';
import '../chores/chore_row.dart';
import '../history/leaderboard.dart';
import '../household/picture_artwork.dart';
import 'household_members_row.dart';

/// Home screen — household picture, members row, today's chores list,
/// and leaderboard. The whole body scrolls as one — the picture is part
/// of the scrollable content, not a fixed header.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCurrent = ref.watch(currentHouseholdControllerProvider);
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    final householdName =
        asyncCurrent.valueOrNull?.name ?? 'Have You Fed The Dog?';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Picture extends behind the transparent status bar — the system
      // bar text (clock / battery) floats over the sky portion of the
      // image. Icon brightness follows the theme: evening/night runs the
      // app in dark mode over a dusky sky, where dark icons would vanish.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            final currentId = asyncCurrent.valueOrNull?.id;
            await Future.wait([
              ref.read(subjectsControllerProvider.notifier).refresh(),
              ref.read(choresControllerProvider.notifier).refresh(),
              ref.read(todayCompletionsControllerProvider.notifier).refresh(),
              // Members (avatars) + history (leaderboard) sync from other
              // devices — the refresh people pull for most.
              ref.read(householdHistoryControllerProvider.notifier).refresh(),
              if (currentId != null)
                ref
                    .read(householdMembersControllerProvider(currentId)
                        .notifier)
                    .refresh(),
            ]);
          },
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
              children: [
                if (asyncCurrent.valueOrNull != null) ...[
                  _HouseHero(household: asyncCurrent.value!),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      householdName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  HouseholdMembersRow(householdId: asyncCurrent.value!.id),
                  const SizedBox(height: 16),
                ],
                ...asyncSubjects.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        character: CharacterRegistry.generic,
                        title: 'Hmm, something went sideways',
                        message: 'Could not load your friends. $e',
                        actionLabel: 'Try again',
                        onAction: () => ref
                            .read(subjectsControllerProvider.notifier)
                            .refresh(),
                      ),
                    ),
                  ],
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      // A different friend fronts the empty state on each
                      // load/refresh. Seeding from the list instance keeps
                      // the pick stable across unrelated rebuilds (theme
                      // flips, other providers) — it only reshuffles when
                      // the controller actually emits a fresh fetch.
                      final candidates = [
                        for (final c in CharacterRegistry.all)
                          if (c != CharacterRegistry.generic) c,
                      ];
                      final greeter = candidates[
                          Random(identityHashCode(subjects))
                              .nextInt(candidates.length)];
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            character: greeter,
                            title: 'No friends yet',
                            message:
                                'Add a dog, cat, plant, or whatever else needs '
                                'looking after.',
                            actionLabel: 'Add a friend',
                            onAction: () => context.push(Routes.subjectNew),
                          ),
                        ),
                      ];
                    }
                    final allChores =
                        ref.watch(choresControllerProvider).valueOrNull ??
                        const <Chore>[];
                    final completions =
                        ref
                            .watch(todayCompletionsControllerProvider)
                            .valueOrNull ??
                        const <Completion>[];
                    final tasks = _todaysTasks(
                      subjects: subjects,
                      chores: allChores,
                      completions: completions,
                    );
                    final doneCount = tasks
                        .where((t) => t.completion != null)
                        .length;
                    final totalCount = tasks.length;
                    final myName = ref
                        .watch(authControllerProvider)
                        .valueOrNull
                        ?.displayName;
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (totalCount > 0) ...[
                              _TodaySummaryCard(
                                done: doneCount,
                                total: totalCount,
                                myName: myName,
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (tasks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Builder(builder: (context) {
                                  // One of the household's own friends
                                  // snoozes through the day off. Seeded
                                  // from the list instance so it doesn't
                                  // reshuffle on unrelated rebuilds.
                                  final sleeper = subjects[
                                      Random(identityHashCode(subjects))
                                          .nextInt(subjects.length)];
                                  final character =
                                      CharacterRegistry.lookup(sleeper.icon);
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: ClipOval(
                                          child: CharacterArtwork(
                                            character: character,
                                            expression:
                                                CharacterExpression.sleeping,
                                            stage: true,
                                            iconSize: 72,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nothing due today 🎉',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  );
                                }),
                              )
                            else ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 12,
                                ),
                                child: Text(
                                  "Today's chores",
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              for (final t in tasks) ...[
                                ChoreRow(
                                  chore: t.chore,
                                  subjectId: t.subject.id,
                                  existingCompletion: t.completion,
                                  leading: _CharacterAvatar(
                                    subject: t.subject,
                                    expression: _expressionFor(t),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                            const SizedBox(height: 16),
                            if (asyncCurrent.valueOrNull != null)
                              Leaderboard(householdId: asyncCurrent.value!.id),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      // FAB now lives on the bottom-nav shell, central-docked over the
      // notch — handled by `RootNavShell`.
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

/// "X of Y done today" hero card with a progress bar and an encouraging
/// line. Sits between the house picture and the chore tile list.
/// House picture hero on the home screen. Full-width tappable square
/// showing the time-of-day variant of the household's chosen [Picture],
/// with a purple edit-pencil badge in the bottom-right.
class _HouseHero extends StatelessWidget {
  final Household household;
  const _HouseHero({required this.household});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(Routes.householdDetails(household.id)),
      child: AspectRatio(
        aspectRatio: 5 / 4,
        child: Stack(
          children: [
            Positioned.fill(
              child: PictureArtwork(
                picture: PictureRegistry.lookup(household.picture),
                fit: BoxFit.cover,
              ),
            ),
            // Soft dark gradient at the top — helps the status-bar text
            // (clock / battery) read on bright sky variants.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Two diagonal wedges at the bottom corners — each is cream
            // at its own bottom corner, fading to transparent toward the
            // opposite top corner. Drawn FIRST so the vertical strip
            // below paints over the bottom edge cleanly.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Theme.of(context).colorScheme.surface,
                            ],
                            // Stays fully transparent from the top-right
                            // (0%) all the way to 65% along the diagonal,
                            // then fades to cream by the bottom-left
                            // corner. Cream concentrates at the corner
                            // instead of washing over the whole wedge.
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Theme.of(context).colorScheme.surface,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Vertical cream strip drawn AFTER the wedges so it covers
            // their bottom edge with a clean fade. Gives a solid cream
            // base; the wedges show through above it where the corners
            // curl up.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Theme.of(context).colorScheme.surface,
                      ],
                      stops: const [0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.edit, size: 16, color: scheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final int done;
  final int total;
  final String? myName;

  const _TodaySummaryCard({
    required this.done,
    required this.total,
    required this.myName,
  });

  String get _line {
    if (total == 0) return 'Nothing on today.';
    if (done == 0) return "Let's get going!";
    if (done == total) {
      return 'All done! 💚';
    }
    return 'Great job - keep it up!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : done / total;
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              child: Icon(
                Icons.home_outlined,
                color: Colors.green.shade900,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$done of $total done today',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _line,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: Colors.green.shade100,
                      valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44×44 circular avatar showing the subject's character on its stage
/// colour. Used as the leading slot on home-screen chore rows. Pass the
/// [expression] that matches the chore's state (happy for done, sad for
/// overdue, idle otherwise).
class _CharacterAvatar extends StatelessWidget {
  final Subject subject;
  final CharacterExpression expression;
  const _CharacterAvatar({
    required this.subject,
    this.expression = CharacterExpression.idle,
  });

  @override
  Widget build(BuildContext context) {
    final character = CharacterRegistry.lookup(subject.icon);
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipOval(
        child: ColoredBox(
          color: character.stageColor,
          child: CharacterArtwork(
            character: character,
            expression: expression,
            stage: false,
            iconSize: 28,
          ),
        ),
      ),
    );
  }
}

/// One row to render: the chore, its subject, and (if logged) the
/// matching completion.
class _TodayTask {
  final Chore chore;
  final Subject subject;
  final Completion? completion;
  const _TodayTask({
    required this.chore,
    required this.subject,
    required this.completion,
  });
}

/// Picks the right character expression for a today-tile:
/// happy when the chore is logged, sad when it's overdue, idle otherwise.
CharacterExpression _expressionFor(_TodayTask t) {
  if (t.completion != null) return CharacterExpression.happy;
  final scheduledAt = t.chore.rule.scheduledAt(DateTime.now());
  if (scheduledAt.isBefore(DateTime.now())) return CharacterExpression.sad;
  return CharacterExpression.idle;
}

/// Builds the sorted list of today's chores across all subjects.
/// Sorted by scheduled time ascending. Pending and done are interleaved
/// in time order.
List<_TodayTask> _todaysTasks({
  required List<Subject> subjects,
  required List<Chore> chores,
  required List<Completion> completions,
}) {
  final now = DateTime.now();
  final subjectById = <String, Subject>{for (final s in subjects) s.id: s};
  final completionByChoreId = <String, Completion>{
    for (final c in completions)
      if (c.choreId != null) c.choreId!: c,
  };

  final out = <_TodayTask>[];
  for (final chore in chores) {
    if (!chore.rule.isDueOn(now)) continue;
    final subject = subjectById[chore.subjectId];
    if (subject == null) continue;
    out.add(
      _TodayTask(
        chore: chore,
        subject: subject,
        completion: completionByChoreId[chore.id],
      ),
    );
  }
  out.sort((a, b) {
    final ta = a.chore.rule.scheduledAt(now);
    final tb = b.chore.rule.scheduledAt(now);
    return ta.compareTo(tb);
  });
  return out;
}
