import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';

/// Full-screen "Nice work!" overlay shown after a chore is logged.
///
/// Confetti shower, the subject's character in a celebrating expression,
/// the chore name, and a "by Whoever" subtitle. Auto-dismisses after ~3
/// seconds; the "Nice!" button bails earlier.
///
/// Use [show] to push the route — keeps the call sites in `ChoreRow` /
/// `ChoreChipWithTap` to a single line.
class CompletionCelebration extends StatefulWidget {
  final Character character;
  final String choreName;
  final String? whoName;

  const CompletionCelebration({
    super.key,
    required this.character,
    required this.choreName,
    this.whoName,
  });

  /// Pushes the celebration as a full-screen dialog route. Resolves when
  /// the user (or the auto-dismiss timer) closes it. Safe to fire-and-
  /// forget — the calling code keeps moving while the overlay is up.
  static Future<void> show(
    BuildContext context, {
    required Character character,
    required String choreName,
    String? whoName,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: CompletionCelebration(
            character: character,
            choreName: choreName,
            whoName: whoName,
          ),
        ),
      ),
    );
  }

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
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
    Navigator.of(context).maybePop();
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

    return Scaffold(
      backgroundColor: widget.character.stageColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti emitting straight up from below the centre.
            Align(
              alignment: const Alignment(0, 0.2),
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
                        character: widget.character,
                        expression: CharacterExpression.celebrating,
                        stage: false,
                        iconSize: 160,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${widget.choreName}\nAll done!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.whoName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Logged by ${widget.whoName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
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
                          horizontal: 48, vertical: 16),
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
