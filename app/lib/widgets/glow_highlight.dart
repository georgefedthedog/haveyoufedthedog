import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps a child and, when [flash] is called, pulses a soft primary-coloured
/// glow around it once (rise then fall) - the app's shared "look here" cue
/// after scrolling something into view (the invite card, the act-as card, the
/// rewards collection).
///
/// Drive it through a `GlobalKey<GlowHighlightState>`: scroll the key's
/// context into view, then call `key.currentState?.flash()`.
class GlowHighlight extends StatefulWidget {
  final Widget child;

  /// Corner radius of the glow - match the wrapped card's radius (Cards are 12).
  final double borderRadius;

  const GlowHighlight({super.key, required this.child, this.borderRadius = 12});

  @override
  State<GlowHighlight> createState() => GlowHighlightState();
}

class GlowHighlightState extends State<GlowHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Play one rise-and-fall glow.
  void flash() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Single rise-and-fall over the animation; zero at rest (no shadow).
        final glow = sin(_controller.value * pi).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.55 * glow),
                blurRadius: 24 * glow,
                spreadRadius: 1.5 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
