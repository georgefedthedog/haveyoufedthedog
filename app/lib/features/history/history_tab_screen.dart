import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/completions/awards_controller.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/completions/stats_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../widgets/page_title.dart';
import 'awards_section.dart';
import 'leaderboard.dart';

/// Awards tab - household-wide. Quick-stats strip at the top, then the
/// featured awards, leaderboard, and badge cabinet. (The "All activity"
/// completion feed lives at the bottom of the Home page.)
class HistoryTabScreen extends ConsumerWidget {
  const HistoryTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(householdHistoryControllerProvider);
    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;

    // Status-bar inset as scroll padding, not SafeArea: content starts
    // below the status bar but scrolls clean to the physical top edge
    // instead of clipping at the inset line.
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(householdHistoryControllerProvider.notifier).refresh(),
        child: asyncHistory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
            children: [
              const PageTitle(text: 'Awards'),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load history: $e'),
              ),
            ],
          ),
          data: (_) => ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 96),
            children: [
              const PageTitle(text: 'Awards'),
              const _StatsStrip(),
              const SizedBox(height: 20),
              if (hh != null) ...[
                FeaturedAwards(householdId: hh.id),
                const SizedBox(height: 20),
                Leaderboard(householdId: hh.id),
                const SizedBox(height: 20),
                BadgesSection(householdId: hh.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One compact strip combining the household's quick stats - streak,
/// completions this week, clean sweeps - as three segments with vertical
/// dividers, like a scoreboard.
class _StatsStrip extends ConsumerWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(householdStreakProvider);
    final thisWeek = ref.watch(currentWeekStatsProvider);
    final sweeps = ref.watch(weeklyAwardsProvider).cleanSweeps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _StatSegment(
                glyph: const Text('🔥', style: TextStyle(fontSize: 20)),
                value: '$streak',
                label: streak == 1 ? 'Day streak' : 'Day streak',
              ),
              const VerticalDivider(width: 1),
              _StatSegment(
                glyph: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                value: '${thisWeek.total}',
                label: 'This week',
              ),
              const VerticalDivider(width: 1),
              _StatSegment(
                glyph: const Text('✨', style: TextStyle(fontSize: 20)),
                value: '$sweeps',
                label: sweeps == 1 ? 'Clean sweep' : 'Clean sweeps',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatSegment extends StatelessWidget {
  final Widget glyph;
  final String value;
  final String label;

  const _StatSegment({
    required this.glyph,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
