import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../profile/avatar_artwork.dart';
import 'celebration_args.dart';

/// Full-screen "Nice work!" overlay shown after a chore is logged.
///
/// Confetti shower, the subject's character in a celebrating expression,
/// the chore name, and a "by Whoever" subtitle. Auto-dismisses after ~3
/// seconds; the "Nice!" button bails earlier.
///
/// Mounted as a real [GoRoute] (`/celebration`) so anyone with the router
/// instance can push it - including code outside the widget tree (the NFC
/// handler). Push via `context.push(Routes.celebration, extra: args)` from
/// a widget, or `ref.read(appRouterProvider).push(...)` from a controller.
class CompletionCelebration extends ConsumerStatefulWidget {
  final CelebrationArgs args;

  const CompletionCelebration({super.key, required this.args});

  @override
  ConsumerState<CompletionCelebration> createState() =>
      _CompletionCelebrationState();
}

class _CompletionCelebrationState extends ConsumerState<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pop;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _pop.forward();
    });
    _autoDismiss = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    if (!mounted) return;
    if (context.canPop()) context.pop();
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
    final scheme = theme.colorScheme;

    final args = widget.args;
    return Scaffold(
      backgroundColor: args.character.stageColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti emitting straight up from below the centre.
            Align(
              alignment: const Alignment(0, -0.6),
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: -pi / 2, // straight up
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 24,
                gravity: 0.18,
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
                      height: 220,
                      child: CharacterArtwork(
                        character: args.character,
                        expression: CharacterExpression.celebrate,
                        stage: false,
                        iconSize: 160,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${args.choreName}\nAll done!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  if (args.streak >= 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        args.streak == 1
                            ? '🔥 Streak started!'
                            : '🔥 ${args.streak} day streak!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  if (args.whoName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarArtwork(
                            avatar: ref
                                .watch(catalogProvider)
                                .lookupAvatar(args.whoAvatar),
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Logged by ${args.whoName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _dismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Nice!'),
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
