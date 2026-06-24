import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/completions/reward_streak_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../router/routes.dart';
import 'wiggling_present.dart';

/// A tappable reward-streak progress strip (🎁 + "X/threshold" bar) that
/// pushes the free-rewards page. Card-less by design: on the Awards tab it
/// sits *inside* the stats card under the scoreboard (with a [leadingDivider]
/// separating them); on the store page it's wrapped in its own card with
/// [leadingDivider] off.
///
/// Uses a 🎁 glyph rather than the day streak's 🔥 so the two aren't confused.
/// Renders nothing until a household is resolved. Reads the same advisory
/// [householdRewardStreakProvider] the rewards page uses.
class StreakRewardBar extends ConsumerWidget {
  /// A divider above the row - true when embedded under the stats scoreboard,
  /// false when it's the sole content of its own card.
  final bool leadingDivider;

  const StreakRewardBar({super.key, this.leadingDivider = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    if (household == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final threshold = household.rewardStreakThreshold;
    final streak = ref.watch(householdRewardStreakProvider).valueOrNull ?? 0;
    final ready = streak >= threshold;
    final progress = threshold == 0 ? 0.0 : (streak / threshold).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingDivider) const Divider(height: 1),
        InkWell(
          onTap: () => context.push(Routes.rewards),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                WigglingPresent(active: ready),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ready
                                  ? 'Free reward available!'
                                  : 'Free reward streak',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '$streak/$threshold',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ready
                                  ? scheme.tertiary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: ready ? scheme.tertiary : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
