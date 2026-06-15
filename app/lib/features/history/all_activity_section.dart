import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/completions/household_history_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../widgets/empty_state.dart';
import 'completion_timeline.dart';

/// The household-wide "All activity" feed: a centred section title, an
/// optional subject filter-chip row, and the full completion timeline (or
/// an empty state). Lives at the bottom of the Home page.
///
/// Holds its own [_subjectFilter] state. Pass [initialSubjectFilter] to
/// open pre-filtered to one subject - the subject detail screen's
/// "See all" deep-links here via `/?subject=<id>`.
class AllActivitySection extends ConsumerStatefulWidget {
  final String? initialSubjectFilter;

  const AllActivitySection({super.key, this.initialSubjectFilter});

  @override
  ConsumerState<AllActivitySection> createState() =>
      _AllActivitySectionState();
}

class _AllActivitySectionState extends ConsumerState<AllActivitySection> {
  String? _subjectFilter; // null = all subjects

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubjectFilter;
  }

  @override
  void didUpdateWidget(covariant AllActivitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh deep-link (subject detail "See all") re-enters the Home
    // branch with a new subject id. Honour it even when this section's
    // State was kept alive across tab swipes. A plain Home navigation
    // carries no subject param (null), so a manual chip choice survives.
    final incoming = widget.initialSubjectFilter;
    if (incoming != null && incoming != oldWidget.initialSubjectFilter) {
      setState(() => _subjectFilter = incoming);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncHistory = ref.watch(householdHistoryControllerProvider);
    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final subjects =
        ref.watch(subjectsControllerProvider).valueOrNull ?? const [];

    final list = asyncHistory.valueOrNull ?? const [];
    final filtered = _subjectFilter == null
        ? list
        : list.where((c) => c.subjectId == _subjectFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'All activity',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (subjects.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Wrap centres the chips (and flows onto a second line if a
            // household has lots of subjects).
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
        if (asyncHistory.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          Builder(
            builder: (context) {
              // When a subject filter is active, its own character fronts
              // the empty state; "All" falls back to the plant.
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
                  : ref.watch(catalogProvider).lookupCharacter(filteredIcon);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  character: character,
                  title: 'Nothing here yet!',
                  message: 'Be the first one to complete a chore.',
                ),
              );
            },
          )
        else
          CompletionTimeline(
            completions: filtered,
            householdId: hh?.id ?? '',
          ),
      ],
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
