import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completed_once_chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/wiggle.dart';
import '../chores/chore_row.dart';
import '../history/all_activity_section.dart';
import '../history/leaderboard.dart';
import '../household/picture_artwork.dart';
import 'household_members_row.dart';

/// Home screen - household picture, members row, today's chores list,
/// and leaderboard. The whole body scrolls as one - the picture is part
/// of the scrollable content, not a fixed header.
class HomeScreen extends ConsumerStatefulWidget {
  /// Optional `?subject=<id>` query param - the subject detail screen's
  /// "See all" deep-links here to open All activity pre-filtered to one pet,
  /// scrolling the page down to it.
  final String? initialSubjectFilter;

  const HomeScreen({super.key, this.initialSubjectFilter});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _allActivityKey = GlobalKey();

  /// Set when we arrive with a subject filter but the All activity section
  /// isn't laid out yet (household/subjects still loading). Each build
  /// retries the scroll post-frame until the section's context exists.
  bool _pendingActivityScroll = false;

  @override
  void initState() {
    super.initState();
    _pendingActivityScroll = widget.initialSubjectFilter != null;
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh "See all" deep-link re-enters this (kept-alive) branch with a
    // new subject id - scroll to the feed again.
    final incoming = widget.initialSubjectFilter;
    if (incoming != null && incoming != oldWidget.initialSubjectFilter) {
      _pendingActivityScroll = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToActivity() async {
    if (!_pendingActivityScroll) return;
    if (!_scrollController.hasClients) {
      return; // Not attached - retry next build.
    }
    _pendingActivityScroll = false;

    // The All activity section is the last child of a lazy ListView, so
    // while it's off-screen it isn't built and its GlobalKey has no context
    // to ensureVisible against. Animate toward the bottom in passes - each
    // scroll builds more children (and grows the real maxScrollExtent) until
    // the section materialises, then align its title to the top.
    for (var pass = 0; pass < 6; pass++) {
      final ctx = _allActivityKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0,
        );
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= max - 1) break; // Already at the bottom.
      await _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      if (!mounted || !_scrollController.hasClients) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingActivityScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToActivity();
      });
    }

    final asyncCurrent = ref.watch(currentHouseholdControllerProvider);
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    final householdName =
        asyncCurrent.valueOrNull?.name ?? 'Have You Fed The Dog?';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Picture extends behind the transparent status bar - the system
      // bar text (clock / battery) floats over the sky portion of the
      // image. Icon brightness follows the theme: evening/night runs the
      // app in dark mode over a dusky sky, where dark icons would vanish.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
              // devices - the refresh people pull for most.
              ref.read(householdHistoryControllerProvider.notifier).refresh(),
              if (currentId != null)
                ref
                    .read(
                      householdMembersControllerProvider(currentId).notifier,
                    )
                    .refresh(),
            ]);
          },
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
              children: [
                if (asyncCurrent.valueOrNull != null) ...[
                  _HouseHero(household: asyncCurrent.value!),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      householdName,
                      textAlign: TextAlign.center,
                      // Same display slot as the subject hero's message
                      // title - keeps the two hero surfaces consistent.
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  // "Who lives here?" - a warm subtitle when set.
                  if (asyncCurrent.value!.residents != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        asyncCurrent.value!.residents!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
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
                        message: 'Could not load your things. $e',
                        actionLabel: 'Try again',
                        onAction: () => ref
                            .read(subjectsControllerProvider.notifier)
                            .refresh(),
                      ),
                    ),
                  ],
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      // A different thing fronts the empty state on each
                      // load/refresh. Seeding from the list instance keeps
                      // the pick stable across unrelated rebuilds (theme
                      // flips, other providers) - it only reshuffles when
                      // the controller actually emits a fresh fetch.
                      final candidates = [
                        for (final c in CharacterRegistry.all)
                          if (c != CharacterRegistry.generic) c,
                      ];
                      final greeter =
                          candidates[Random(
                            identityHashCode(subjects),
                          ).nextInt(candidates.length)];
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            character: greeter,
                            title: 'No things yet',
                            message:
                                'Add a dog, cat, plant, or whatever else needs '
                                'looking after.',
                            actionLabel: 'Add a thing',
                            actionIcon: Icons.pets,
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
                    final completedOnceIds =
                        ref
                            .watch(completedOnceChoreIdsControllerProvider)
                            .valueOrNull ??
                        const <String>{};
                    final tasks = _todaysTasks(
                      subjects: subjects,
                      chores: allChores,
                      completions: completions,
                      completedOnceIds: completedOnceIds,
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
                                child: Builder(
                                  builder: (context) {
                                    // One of the household's own things
                                    // snoozes through the day off. Seeded
                                    // from the list instance so it doesn't
                                    // reshuffle on unrelated rebuilds.
                                    final sleeper =
                                        subjects[Random(
                                          identityHashCode(subjects),
                                        ).nextInt(subjects.length)];
                                    final character = ref
                                        .watch(catalogProvider)
                                        .lookupCharacter(sleeper.icon);
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
                                  },
                                ),
                              )
                            else ...[
                              Text(
                                "Today's chores",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Tap to complete',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
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
                                  // Subject portrait opens the subject; the
                                  // status icon opens the chore editor. Taps
                                  // elsewhere on the row still complete it.
                                  onLeadingTap: () => context.push(
                                    Routes.subjectDetail(t.subject.id),
                                  ),
                                  onTrailingTap: () => context.push(
                                    Routes.choreEdit(t.chore.id),
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
                if (asyncCurrent.valueOrNull != null)
                  Padding(
                    key: _allActivityKey,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: AllActivitySection(
                      initialSubjectFilter: widget.initialSubjectFilter,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // FAB now lives on the bottom-nav shell, central-docked over the
      // notch - handled by `RootNavShell`.
    );
  }
}

/// "X of Y done today" hero card with a progress bar and an encouraging
/// line. Sits between the house picture and the chore tile list.
/// House picture hero on the home screen. Full-width tappable square
/// showing the time-of-day variant of the household's chosen [Picture],
/// with a purple edit-pencil badge in the bottom-right.
class _HouseHero extends ConsumerWidget {
  final Household household;
  const _HouseHero({required this.household});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                picture: ref
                    .watch(catalogProvider)
                    .lookupPicture(household.picture),
                fit: BoxFit.cover,
              ),
            ),
            // Soft dark gradient at the top - helps the status-bar text
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
            // Two diagonal wedges at the bottom corners - each is cream
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : done / total;
    final allDone = total > 0 && done == total;

    final title = allDone
        ? 'All chores done today!'
        : done == 0
        ? "Let's get started!"
        : 'Good progress. Keep it up!';
    final subtitle = '$done of $total completed';

    // Fixed lavender pair (rather than scheme.primaryContainer) so the
    // card reads as the same soft purple in light AND dark mode - matches
    // the celebration-style mockup.
    const cardColor = AppColors.violetSoft;
    const inkColor = AppColors.onVioletSoft;

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      // A finished day is worth celebrating - confetti + cup overlay,
      // which then lands on the Awards tab.
      child: InkWell(
        onTap: allDone ? () => context.push(Routes.dayCelebration) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              // The day's journey in one glyph: flag at the start line,
              // a growing shoot once underway, the trophy when done.
              if (allDone)
                const _WigglingCup()
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.violet.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      done == 0 ? '💤' : '🐾',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: inkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: inkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.violet.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "all done" trophy on the summary card, nudged every few seconds so it
/// invites a tap (which opens the day celebration). Reuses the shared
/// [Wiggle] / [WiggleController] shake by self-poking on a timer.
class _WigglingCup extends StatefulWidget {
  const _WigglingCup();

  @override
  State<_WigglingCup> createState() => _WigglingCupState();
}

class _WigglingCupState extends State<_WigglingCup> {
  final _wiggle = WiggleController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A short shake straight away, then a recurring nudge.
    WidgetsBinding.instance.addPostFrameCallback((_) => _wiggle.poke());
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _wiggle.poke());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wiggle(
      controller: _wiggle,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.asset(
          'assets/awards/all_done_cup.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// 44×44 circular avatar showing the subject's character on its stage
/// colour. Used as the leading slot on home-screen chore rows. Pass the
/// [expression] that matches the chore's state (happy for done, sad for
/// overdue, idle otherwise).
class _CharacterAvatar extends ConsumerWidget {
  final Subject subject;
  final CharacterExpression expression;
  const _CharacterAvatar({
    required this.subject,
    this.expression = CharacterExpression.idle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(catalogProvider).lookupCharacter(subject.icon);
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
  required Set<String> completedOnceIds,
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

    final completion = completionByChoreId[chore.id];
    // A one-off carries over until it's done, but once finished it should drop
    // off the list. It still shows as done on its completion day (matched in
    // today's completions above); a completed one-off with no completion *today*
    // was done on a prior day, so hide it - covering the gap until the worker
    // flips it inactive.
    if (chore.isOnce &&
        completion == null &&
        completedOnceIds.contains(chore.id)) {
      continue;
    }

    out.add(
      _TodayTask(
        chore: chore,
        subject: subject,
        completion: completion,
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
