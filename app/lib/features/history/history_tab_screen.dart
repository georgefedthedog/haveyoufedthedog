import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/completions/awards_controller.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/completions/stats_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../widgets/empty_state.dart';
import 'awards_section.dart';
import 'completion_timeline.dart';
import 'leaderboard.dart';

/// History tab — household-wide. Stats cards at the top, leaderboard
/// underneath, then a filter chip row + the full list of completions.
class HistoryTabScreen extends ConsumerStatefulWidget {
  /// Optional `?subject=<id>` query param from the deep-link — e.g. when
  /// "See all" is tapped on a subject detail screen.
  final String? initialSubjectFilter;

  const HistoryTabScreen({super.key, this.initialSubjectFilter});

  @override
  ConsumerState<HistoryTabScreen> createState() => _HistoryTabScreenState();
}

class _HistoryTabScreenState extends ConsumerState<HistoryTabScreen> {
  String? _subjectFilter; // null = all subjects

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubjectFilter;
  }

  @override
  Widget build(BuildContext context) {
    final asyncHistory = ref.watch(householdHistoryControllerProvider);
    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final subjects =
        ref.watch(subjectsControllerProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Awards'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(householdHistoryControllerProvider.notifier).refresh(),
        child: asyncHistory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load history: $e'),
              ),
            ],
          ),
          data: (list) {
            final filtered = _subjectFilter == null
                ? list
                : list
                    .where((c) => c.subjectId == _subjectFilter)
                    .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _StatsStrip(),
                const SizedBox(height: 20),
                if (hh != null) ...[
                  FeaturedAwards(householdId: hh.id),
                  const SizedBox(height: 20),
                  Leaderboard(householdId: hh.id),
                  const SizedBox(height: 20),
                  BadgesSection(householdId: hh.id),
                  const SizedBox(height: 8),
                ],
                Text('All activity',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 8),
                if (subjects.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    // Wrap centres the chips (and flows onto a second
                    // line if a household has lots of subjects).
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(label: 'All', value: null),
                        for (final s in subjects)
                          _filterChip(label: s.name, value: s.id),
                      ],
                    ),
                  ),
                if (filtered.isEmpty)
                  Builder(builder: (context) {
                    // When a subject filter is active, its own character
                    // fronts the empty state; "All" falls back to the
                    // plant.
                    String? filteredIcon;
                    if (_subjectFilter != null) {
                      for (final s in subjects) {
                        if (s.id == _subjectFilter) {
                          filteredIcon = s.icon;
                          break;
                        }
                      }
                    }
                    final character = _subjectFilter == null
                        ? CharacterRegistry.plant
                        : CharacterRegistry.lookup(filteredIcon);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        character: character,
                        title: 'Nothing here yet!',
                        message: 'Be the first one to complete a chore.',
                      ),
                    );
                  })
                else
                  CompletionTimeline(
                    completions: filtered,
                    householdId: hh?.id ?? '',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required String? value}) {
    return FilterChip(
      label: Text(label),
      selected: _subjectFilter == value,
      onSelected: (_) => setState(() => _subjectFilter = value),
    );
  }
}

/// One compact strip combining the household's quick stats — streak,
/// completions this week, clean sweeps — as three segments with vertical
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
                glyph: Icon(Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.tertiary),
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
