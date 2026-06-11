import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/completions/stats_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../widgets/empty_state.dart';
import '../subjects/completion_tile.dart';
import 'awards_section.dart';
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
                if (hh != null) ...[
                  Leaderboard(householdId: hh.id),
                  const SizedBox(height: 20),
                  Text("This week's awards",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  AwardsSection(householdId: hh.id),
                  const SizedBox(height: 8),
                ],
                Text('Household achievements',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const _StatRow(),
                const SizedBox(height: 12),
                const HouseholdAchievementsRow(),
                const SizedBox(height: 20),
                Text('All activity',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 8),
                if (subjects.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(label: 'All', value: null),
                          for (final s in subjects)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _filterChip(
                                  label: s.name, value: s.id),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      character: CharacterRegistry.plant,
                      title: 'Nothing here yet',
                      message: 'Tap a chore on Home to log the first one.',
                    ),
                  )
                else
                  for (final c in filtered)
                    _CompletionRow(completion: c, householdId: hh?.id ?? ''),
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

class _CompletionRow extends StatelessWidget {
  final Completion completion;
  final String householdId;
  const _CompletionRow({required this.completion, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return CompletionTile(
      completion: completion,
      householdId: householdId,
    );
  }
}

class _StatRow extends ConsumerWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(householdStreakProvider);
    final thisWeek = ref.watch(currentWeekStatsProvider);
    final lastWeek = ref.watch(previousWeekStatsProvider);
    final delta = thisWeek.total - lastWeek.total;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Streak',
            value: streak.toString(),
            subtitle: streak >= 3
                ? 'On fire!'
                : (streak > 0 ? 'Keep it up!' : 'Tap a chore to start.'),
            accent: AppColors.streakOrange,
            accentSoft: AppColors.streakOrangeSoft,
            emoji: '🔥',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'This week',
            value: thisWeek.total.toString(),
            subtitle: delta == 0
                ? 'Same as last week'
                : delta > 0
                    ? '+$delta from last week'
                    : '$delta from last week',
            accent: Theme.of(context).colorScheme.tertiary,
            accentSoft:
                Theme.of(context).colorScheme.tertiaryContainer,
            icon: Icons.check,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final Color accentSoft;

  /// Pass exactly one of [emoji] or [icon] for the badge glyph — an icon
  /// renders tinted with [accent], an emoji in its own colours.
  final String? emoji;
  final IconData? icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.accentSoft,
    this.emoji,
    this.icon,
  }) : assert(emoji != null || icon != null,
            'StatCard needs an emoji or an icon');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: icon != null
                      ? Icon(icon, size: 16, color: accent)
                      : Text(emoji!,
                          style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
