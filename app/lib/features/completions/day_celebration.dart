import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/completions/today_completions_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/profile/avatars.dart';
import '../../router/routes.dart';
import '../profile/avatar_artwork.dart';

/// Full-screen "every chore done today!" celebration — the household-wide
/// big sibling of [CompletionCelebration]. Confetti shower around the
/// trophy cup with everyone who pitched in beneath it, then on dismiss
/// (button or auto-timer) it lands on the Awards tab rather than back
/// where it came from.
class DayCelebration extends ConsumerStatefulWidget {
  const DayCelebration({super.key});

  @override
  ConsumerState<DayCelebration> createState() => _DayCelebrationState();
}

class _DayCelebrationState extends ConsumerState<DayCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pop;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _pop.forward();
    });
    _autoDismiss = Timer(const Duration(milliseconds: 5000), _toAwards);
  }

  void _toAwards() {
    _autoDismiss?.cancel();
    if (!mounted) return;
    // go() replaces the whole stack — the overlay unmounts and the shell
    // lands on the Awards tab.
    context.go(Routes.historyTab);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Everyone who logged at least one of today's completions — the
    // hands the cup belongs to.
    final completions =
        ref.watch(todayCompletionsControllerProvider).valueOrNull ??
            const [];
    final hh = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final members = hh == null
        ? const <HouseholdMember>[]
        : ref.watch(householdMembersControllerProvider(hh.id)).valueOrNull ??
            const <HouseholdMember>[];
    final completerIds = {for (final c in completions) c.completedById};
    final completers = [
      for (final m in members)
        if (completerIds.contains(m.userId)) m,
    ];

    return Scaffold(
      backgroundColor: AppColors.violetSoft,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: const Alignment(0, -0.6),
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: -pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.12,
                numberOfParticles: 40,
                gravity: 0.15,
                shouldLoop: false,
                colors: const [
                  Color(0xFF6B4FE0),
                  Color(0xFFF0884A),
                  Color(0xFF4FBF85),
                  Color(0xFFFFC857),
                  Color(0xFFE56B6F),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _pop,
                      curve: Curves.elasticOut,
                    ),
                    child: SizedBox(
                      height: 200,
                      child: Image.asset(
                        'assets/awards/all_done_cup.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (completers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Thanks to',
                      textAlign: TextAlign.center,
                      // headlineSmall carries the display font (Knewave).
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onVioletSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final m in completers)
                          Tooltip(
                            message: m.displayName,
                            child: AvatarArtwork(
                              avatar: AvatarRegistry.lookup(m.avatar),
                              size: 44,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'All chores done today!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.onVioletSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The whole house is happy. Nice work, team!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onVioletSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _toAwards,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: AppColors.onViolet,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                    ),
                    child: const Text('See awards'),
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
