import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/wiggle.dart';

/// A 🎁 that periodically shakes while [active], to draw the eye to a
/// claimable reward. Reuses the shared [Wiggle] poked on a 1.2s timer - the
/// same looping-shake mechanic as the all-done trophy cup - so the motion is
/// consistent app-wide. At rest (and when inactive) the angle is zero.
class WigglingPresent extends StatefulWidget {
  final bool active;
  final double size;

  const WigglingPresent({super.key, required this.active, this.size = 22});

  @override
  State<WigglingPresent> createState() => _WigglingPresentState();
}

class _WigglingPresentState extends State<WigglingPresent> {
  final _wiggle = WiggleController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(covariant WigglingPresent old) {
    super.didUpdateWidget(old);
    if (widget.active && _timer == null) {
      _start();
    } else if (!widget.active && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _start() {
    _wiggle.poke(); // an immediate shake, then keep it up
    _timer = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _wiggle.poke(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Wiggle(
    controller: _wiggle,
    child: Text('🎁', style: TextStyle(fontSize: widget.size)),
  );
}
