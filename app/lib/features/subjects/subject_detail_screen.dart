import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/chores/chore.dart';
import '../../core/chores/chore_actions.dart';
import '../../core/chores/chores_controller.dart';
import '../../core/completions/completion.dart';
import '../../core/completions/recent_completions_controller.dart';
import '../../core/completions/streak_controller.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/character_message.dart';
import '../../core/subjects/subject.dart';
import '../../core/subjects/subject_mood_controller.dart';
import '../../core/subjects/subjects_controller.dart';
import '../../router/routes.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../chores/chore_row.dart';
import '../history/completion_timeline.dart';

/// Subject detail - a large character hero up top, status message, today's
/// chores as wide rows, all chores, recent history.
class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubjects = ref.watch(subjectsControllerProvider);

    return asyncSubjects.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (subjects) {
        Subject? subject;
        for (final s in subjects) {
          if (s.id == subjectId) {
            subject = s;
            break;
          }
        }
        if (subject == null) {
          // Subject got deleted underneath us (or we deep-linked to a
          // stale id). Bounce to home rather than dead-end. Use a
          // post-frame callback so we don't navigate during a build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _Body(subject: subject);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  final Subject subject;
  const _Body({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(choresControllerProvider.notifier).refresh(),
            ref.read(todayCompletionsControllerProvider.notifier).refresh(),
            ref
                .read(recentCompletionsControllerProvider(subject.id).notifier)
                .refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: [
            _Hero(subject: subject),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _TodaySection(subject: subject),
                  const SizedBox(height: 24),
                  _ChoresSection(subjectId: subject.id),
                  const SizedBox(height: 24),
                  _HistorySection(subject: subject),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  final Subject subject;
  const _Hero({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(catalogProvider).lookupCharacter(subject.icon);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mood = ref.watch(subjectMoodProvider(subject.id));
    final line = characterLine(
      character: character,
      mood: mood,
      subjectName: subject.name,
    );

    final streak = ref.watch(subjectStreakProvider(subject.id));

    // Gentle diagonal shading on the stage - darker toward the bottom-left,
    // lighter toward the top-right - derived from the stage colour so it
    // works for every character and both themes.
    final stageHsl = HSLColor.fromColor(character.stageColor);
    final stageLight = stageHsl
        .withLightness((stageHsl.lightness + 0.05).clamp(0.0, 1.0))
        .toColor();
    final stageDark = stageHsl
        .withLightness((stageHsl.lightness - 0.07).clamp(0.0, 1.0))
        .toColor();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Stack(
            children: [
              // NFC indicator in the card's top-right corner when a tag
              // is bound to this subject.
              if (subject.nfcTagId != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Tooltip(
                    message: 'NFC tag linked',
                    child: Icon(
                      Icons.nfc,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Full-width so the column centres in the card - inside a
              // Stack it would otherwise shrink-wrap and sit left.
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    // Character floats on a circular stage over the page surface -
                    // the stage colour stays in the circle rather than washing the
                    // whole header.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push(Routes.subjectEdit(subject.id)),
                      child: Stack(
                        // Pins the pencil badge onto the ellipse's bottom-right rim.
                        alignment: const Alignment(0.7, 0.88),
                        children: [
                          Container(
                            width: 220,
                            height: 260,
                            decoration: BoxDecoration(
                              // Ellipse - a circle's border radius stretched to the
                              // box's unequal width/height. Taller than wide, like
                              // an upright egg.
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(110, 130),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [stageDark, stageLight],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: CharacterArtwork(
                              character: character,
                              expression: mood.expression,
                              stage: false,
                              iconSize: 150,
                            ),
                          ),
                          // Small pencil badge on the circle's edge. White ring
                          // gives it a sticker feel against any stage colour.
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (streak >= 3) ...[
                      const SizedBox(height: 12),
                      _StreakPill(streak: streak),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      line.title,
                      textAlign: TextAlign.center,
                      // headlineMedium carries the display font (Knewave) - one
                      // step up from the household name on home.
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
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

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.streakOrangeSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: const TextStyle(
              color: AppColors.streakOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends ConsumerWidget {
  final Subject subject;
  const _TodaySection({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChores = ref.watch(choresControllerProvider);
    final asyncCompletions = ref.watch(todayCompletionsControllerProvider);

    final today = DateTime.now();
    final allChores = asyncChores.valueOrNull ?? const <Chore>[];
    final dueToday =
        allChores
            .where((c) => c.subjectId == subject.id && c.rule.isDueOn(today))
            .toList()
          ..sort(
            (a, b) =>
                (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
          );

    final completions = asyncCompletions.valueOrNull;
    final latestByChoreId = <String, Completion>{};
    if (completions != null) {
      for (final c in completions) {
        final id = c.choreId;
        if (id != null) latestByChoreId.putIfAbsent(id, () => c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's chores",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Tap to complete',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (dueToday.isEmpty)
          Text(
            'Nothing due today 🎉',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final c in dueToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoreRow(
                chore: c,
                subjectId: subject.id,
                existingCompletion: latestByChoreId[c.id],
              ),
            ),
      ],
    );
  }
}

class _ChoresSection extends ConsumerStatefulWidget {
  final String subjectId;
  const _ChoresSection({required this.subjectId});

  @override
  ConsumerState<_ChoresSection> createState() => _ChoresSectionState();
}

class _ChoresSectionState extends ConsumerState<_ChoresSection> {
  /// True while a chore chip is being long-press dragged - the Add slot
  /// morphs into the red Remove drop target for the duration.
  bool _dragging = false;

  Future<void> _confirmAndDelete(Chore chore) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${chore.name}?'),
        content: const Text(
          'Its schedule and reminders go with it. Past completions stay '
          'in the history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(choreActionsProvider).deleteChore(chore.id);
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncChores = ref.watch(choresControllerProvider);
    final chores =
        (asyncChores.valueOrNull ?? const [])
            .where((c) => c.subjectId == widget.subjectId)
            .toList()
          ..sort(
            (a, b) =>
                (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage chores',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final c in chores)
                  _ChoreChip(
                    chore: c,
                    onTap: () => context.push(Routes.choreEdit(c.id)),
                    onDragChanged: (active) =>
                        setState(() => _dragging = active),
                  ),
                if (_dragging)
                  _RemoveChoreChip(onDrop: _confirmAndDelete)
                else
                  _AddChoreChip(
                    onTap: () =>
                        context.push(Routes.choreNew(widget.subjectId)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One chore in the manage-chores cloud: pastel circle with a clock,
/// pencil badge on the edge, name + schedule underneath. Tap to edit;
/// long-press to lift and drag onto the Remove slot to delete.
class _ChoreChip extends StatelessWidget {
  final Chore chore;
  final VoidCallback onTap;

  /// Fired with true when a long-press drag lifts this chip, false when
  /// the drag ends (dropped or cancelled). The parent swaps the Add slot
  /// for the Remove bin while any drag is live.
  final ValueChanged<bool> onDragChanged;

  const _ChoreChip({
    required this.chore,
    required this.onTap,
    required this.onDragChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chip = _chipBody(theme, scheme);
    return LongPressDraggable<Chore>(
      data: chore,
      onDragStarted: () => onDragChanged(true),
      onDragEnd: (_) => onDragChanged(false),
      // The lifted copy swaps its pencil badge for a red cross - you're
      // carrying it toward the bin, not editing it.
      feedback: Material(
        color: Colors.transparent,
        child: _chipBody(theme, scheme, removing: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      ),
    );
  }

  Widget _chipBody(
    ThemeData theme,
    ColorScheme scheme, {
    bool removing = false,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(
                  Icons.schedule,
                  size: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: removing ? Colors.red : scheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    removing ? Icons.close : Icons.edit,
                    size: 11,
                    color: removing ? Colors.white : scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            chore.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chore.rule.humanLabel(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Drop target the Add slot morphs into while a chore chip is being
/// dragged - dashed red circle with a bin, fills solid on hover. Dropping
/// hands the chore to [onDrop] (which confirms before deleting).
class _RemoveChoreChip extends StatelessWidget {
  final ValueChanged<Chore> onDrop;

  const _RemoveChoreChip({required this.onDrop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<Chore>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final red = hovering ? Colors.red : Colors.red.shade300;
        return SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: DashedCirclePainter(color: red, filled: hovering),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.delete_outline,
                    size: 24,
                    color: hovering ? Colors.white : red,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Remove chore',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Trailing "Add chore" affordance - dashed circle with a plus, styled
/// like the chore chips so it reads as the next empty slot.
class _AddChoreChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChoreChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: accent),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add, size: 24, color: accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add chore',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  final Subject subject;
  const _HistorySection({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecent = ref.watch(
      recentCompletionsControllerProvider(subject.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Completed chores',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Center(
          child: TextButton(
            onPressed: () =>
                context.go('${Routes.historyTab}?subject=${subject.id}'),
            child: const Text('See all →'),
          ),
        ),
        const SizedBox(height: 8),
        asyncRecent.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Could not load history: $e'),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No completions logged yet.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return CompletionTimeline(
              completions: list.take(5).toList(),
              householdId: subject.householdId,
            );
          },
        ),
      ],
    );
  }
}
