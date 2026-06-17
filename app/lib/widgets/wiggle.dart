import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared "poke" signal behind the tap-a-target-to-hint affordance: tapping a
/// [DropTargetCircle] pokes a [WiggleController], and every [Wiggle] listening
/// to it does a short random shake so the user discovers the chips are
/// draggable. One controller per screen, shared by the targets and the chips.
class WiggleController extends ChangeNotifier {
  int _pokes = 0;

  /// Bumped on every poke; [Wiggle] watches this to trigger a shake.
  int get pokes => _pokes;

  void poke() {
    _pokes++;
    notifyListeners();
  }
}

/// Wraps a draggable child and shakes it briefly whenever [controller] is
/// poked. Each instance picks a fresh random amplitude, direction, and a small
/// start delay per poke, so a group of chips wiggles loosely rather than in
/// lockstep. At rest the angle is zero, so it never affects normal hit-testing.
class Wiggle extends StatefulWidget {
  final WiggleController controller;
  final Widget child;

  const Wiggle({super.key, required this.controller, required this.child});

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  static final _rng = math.Random();

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Peak swing in radians (signed for direction); re-rolled per poke.
  double _amplitude = 0;
  int _lastPoke = 0;

  @override
  void initState() {
    super.initState();
    _lastPoke = widget.controller.pokes;
    widget.controller.addListener(_onPoke);
  }

  @override
  void didUpdateWidget(covariant Wiggle old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onPoke);
      _lastPoke = widget.controller.pokes;
      widget.controller.addListener(_onPoke);
    }
  }

  void _onPoke() {
    if (widget.controller.pokes == _lastPoke) return;
    _lastPoke = widget.controller.pokes;
    // 7-12 degrees, either direction, after a tiny per-chip stagger.
    _amplitude =
        (0.12 + _rng.nextDouble() * 0.09) * (_rng.nextBool() ? 1 : -1);
    Future.delayed(Duration(milliseconds: _rng.nextInt(120)), () {
      if (mounted) _anim.forward(from: 0);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPoke);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (context, child) {
        final t = _anim.value;
        // Decaying oscillation: a couple of swings that settle back to rest.
        final angle = _amplitude * math.sin(t * math.pi * 3) * (1 - t);
        return Transform.rotate(angle: angle, child: child);
      },
    );
  }
}
