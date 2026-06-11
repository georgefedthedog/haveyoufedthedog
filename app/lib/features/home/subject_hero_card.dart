import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_mood_controller.dart';

/// Home-screen card for one subject. Stage-coloured panel with the
/// character on the left and name + today's progress on the right. The
/// whole card is one tap target — chip-level interaction lives on the
/// subject detail screen now.
class SubjectHeroCard extends ConsumerWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectHeroCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final asyncCompletions = ref.watch(todayCompletionsControllerProvider);

    final character = CharacterRegistry.lookup(subject.icon);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final allChores = asyncChores.valueOrNull ?? const <Chore>[];
    final mineToday = allChores
        .where((c) => c.subjectId == subject.id && c.rule.isDueOn(DateTime.now()))
        .toList();
    final hasAnyChores = allChores.any((c) => c.subjectId == subject.id);

    final doneChoreIds = <String>{
      for (final c in asyncCompletions.valueOrNull ?? const [])
        if (c.choreId != null) c.choreId!,
    };
    final doneCount =
        mineToday.where((c) => doneChoreIds.contains(c.id)).length;
    final total = mineToday.length;
    final allDone = total > 0 && doneCount == total;

    final progressLabel = total == 0
        ? (hasAnyChores ? 'Nothing due today' : 'No chores yet')
        : '$doneCount of $total done today';

    final streak = ref.watch(subjectStreakProvider(subject.id));

    // Same gentle diagonal shading as the subject hero's stage — darker
    // toward the bottom-left, lighter toward the top-right, derived from
    // the stage colour so every character gets a matching lift.
    final stageHsl = HSLColor.fromColor(character.stageColor);
    final stageLight = stageHsl
        .withLightness((stageHsl.lightness + 0.05).clamp(0.0, 1.0))
        .toColor();
    final stageDark = stageHsl
        .withLightness((stageHsl.lightness - 0.07).clamp(0.0, 1.0))
        .toColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              // Character stage on the left.
              SizedBox(
                width: 132,
                height: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [stageDark, stageLight],
                    ),
                  ),
                  child: CharacterArtwork(
                    character: character,
                    expression:
                        ref.watch(subjectMoodProvider(subject.id)).expression,
                    stage: false,
                    iconSize: 56,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subject.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (streak >= 3) _StreakPill(streak: streak),
                          if (subject.nfcTagId != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.nfc,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        progressLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressBar(
                        done: doneCount,
                        total: total,
                        allDone: allDone,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.streakOrangeSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: const TextStyle(
              color: AppColors.streakOrange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final bool allDone;

  const _ProgressBar({
    required this.done,
    required this.total,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : done / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 8,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(
          allDone ? scheme.tertiary : scheme.primary,
        ),
      ),
    );
  }
}
