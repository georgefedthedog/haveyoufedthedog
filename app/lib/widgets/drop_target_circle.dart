import 'package:flutter/material.dart';

import 'dashed_circle_painter.dart';

/// The app's signature "drop here" affordance: a 56x56 dashed ring with an
/// icon and a caption below. The ring fills solid and the icon flips to white
/// while a matching draggable hovers. Generic over the dragged payload [T].
///
/// Tapping the target (rather than dropping onto it) fires [onTap] - used to
/// poke a [WiggleController] so the draggable chips shake and reveal they move.
class DropTargetCircle<T extends Object> extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Resting colour of the ring, icon, and caption.
  final Color baseColor;

  /// Colour while a draggable hovers (ring fill + caption). Defaults to
  /// [baseColor] for sites that don't brighten on hover.
  final Color? hoverColor;

  /// When false the target rejects drops and ignores taps.
  final bool enabled;

  /// Fixed caption width - wraps the label in a [SizedBox] so stacked targets
  /// align. Null lets the caption size to its text.
  final double? labelWidth;

  final int labelMaxLines;

  /// Called with the dropped payload when a drag is accepted. Sites that don't
  /// care about the payload just ignore the argument.
  final ValueChanged<T> onDrop;

  /// Called when the target is tapped instead of dragged onto.
  final VoidCallback? onTap;

  const DropTargetCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.baseColor,
    required this.onDrop,
    this.hoverColor,
    this.enabled = true,
    this.labelWidth,
    this.labelMaxLines = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<T>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final color = hovering ? (hoverColor ?? baseColor) : baseColor;

        Widget caption = Text(
          label,
          textAlign: TextAlign.center,
          maxLines: labelMaxLines,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        );
        if (labelWidth != null) {
          caption = SizedBox(width: labelWidth, child: caption);
        }

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: color, filled: hovering),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  icon,
                  size: 24,
                  color: hovering ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            caption,
          ],
        );

        if (onTap != null) {
          content = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
