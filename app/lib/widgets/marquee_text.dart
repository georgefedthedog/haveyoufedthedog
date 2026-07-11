import 'package:flutter/material.dart';

/// Single-line text that gently auto-scrolls (ping-pong, with pauses) when
/// it's too wide for its space - so long localized award titles stay
/// readable instead of clipping. Renders exactly like a plain [Text] when
/// the string fits. Not user-scrollable; it's a display effect.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Scroll speed in logical pixels per second.
  final double velocity;

  /// Rest time at each end before scrolling again.
  final Duration pause;

  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.velocity = 40,
    this.pause = const Duration(milliseconds: 1500),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final _scroll = ScrollController();

  /// Bumped whenever the text changes (or on dispose) so the async loop
  /// backing the previous string stops itself at its next checkpoint.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.style != widget.style) _restart();
  }

  void _restart() {
    final epoch = ++_epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _epoch || !_scroll.hasClients) return;
      // A fresh (shorter) string mustn't inherit the old scroll offset.
      _scroll.jumpTo(0);
      _loop(epoch);
    });
  }

  Duration _travelTime(double distance) => Duration(
    milliseconds: (distance / widget.velocity * 1000).round().clamp(600, 30000),
  );

  Future<void> _loop(int epoch) async {
    while (true) {
      if (!mounted || epoch != _epoch || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return; // Fits - behave like a plain Text.

      await Future<void>.delayed(widget.pause);
      if (!mounted || epoch != _epoch || !_scroll.hasClients) return;
      await _scroll.animateTo(
        max,
        duration: _travelTime(max),
        curve: Curves.linear,
      );

      if (!mounted || epoch != _epoch || !_scroll.hasClients) return;
      await Future<void>.delayed(widget.pause);
      if (!mounted || epoch != _epoch || !_scroll.hasClients) return;
      await _scroll.animateTo(
        0,
        duration: _travelTime(max),
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _epoch++; // stop the loop at its next checkpoint
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, maxLines: 1, style: widget.style),
    );
  }
}
