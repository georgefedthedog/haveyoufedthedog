import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/profile/avatar.dart';
import '../../widgets/dashed_circle_painter.dart';
import 'avatar_artwork.dart';

/// "Stage + tray" picker for profile avatars. The chosen avatar lives on a
/// big dashed-circle [DragTarget] (the app's signature "drop here" shape);
/// the full set scrolls in a grid tray below. Drag a tray avatar up onto
/// the stage - or just tap it - and the stage gives a springy bounce.
///
/// Scales to a large catalog (the tray scrolls; the stage stays pinned) and
/// needs no filter UI. Same contract as before: pass [selected] (nullable),
/// receive a non-null id via [onChanged].
class AvatarPicker extends ConsumerWidget {
  /// Currently-selected avatar id. Null = nothing chosen yet (stage shows
  /// the inviting empty silhouette).
  final String? selected;

  final ValueChanged<String> onChanged;

  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatars = ref.watch(selectableCatalogProvider).avatars;
    final current = _byId(avatars, selected);

    return Column(
      children: [
        _Stage(
          avatar: current,
          onAccept: (a) => onChanged(a.id),
          onSurprise: avatars.length < 2
              ? null
              : () => onChanged(_randomOther(avatars, selected).id),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag or tap',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // Bounded so the stage stays pinned while the tray scrolls inside.
        // ShaderMask fades the scroll edges so rows dissolve in/out rather
        // than clipping hard against the stage and the form below.
        SizedBox(
          height: 240,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.92, 1.0],
            ).createShader(bounds),
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, i) => _TrayTile(
                avatar: avatars[i],
                selected: avatars[i].id == selected,
                onTap: () => onChanged(avatars[i].id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Avatar? _byId(List<Avatar> avatars, String? id) {
    if (id == null) return null;
    for (final a in avatars) {
      if (a.id == id) return a;
    }
    return null;
  }

  static Avatar _randomOther(List<Avatar> avatars, String? id) {
    final pool = avatars.where((a) => a.id != id).toList();
    return pool[Random().nextInt(pool.length)];
  }
}

/// The hero target. A dashed circle that fills solid + previews the avatar
/// while a tray chip hovers over it, and bounces whenever the selection
/// settles.
class _Stage extends StatefulWidget {
  final Avatar? avatar;
  final ValueChanged<Avatar> onAccept;
  final VoidCallback? onSurprise;

  const _Stage({
    required this.avatar,
    required this.onAccept,
    required this.onSurprise,
  });

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with SingleTickerProviderStateMixin {
  static const _size = 176.0;
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _scale = Tween(
    begin: 0.7,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pop, curve: Curves.elasticOut));

  @override
  void didUpdateWidget(covariant _Stage old) {
    super.didUpdateWidget(old);
    if (widget.avatar?.id != old.avatar?.id && widget.avatar != null) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DragTarget<Avatar>(
      onAcceptWithDetails: (d) => widget.onAccept(d.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final shown = hovering ? candidate.first : widget.avatar;
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: hovering ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: ScaleTransition(
                scale: _scale,
                child: SizedBox(
                  width: _size,
                  height: _size,
                  child: CustomPaint(
                    painter: DashedCirclePainter(
                      color: hovering
                          ? scheme.primaryContainer
                          : scheme.outline,
                      filled: hovering,
                    ),
                    child: Center(
                      child: AvatarArtwork(avatar: shown, size: _size - 14),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onSurprise != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: scheme.secondaryContainer,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Surprise me',
                    color: scheme.onSecondaryContainer,
                    icon: const Icon(Icons.casino),
                    onPressed: widget.onSurprise,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One avatar in the scrollable tray. Long-press to drag onto the stage;
/// tap to select. Mirrors the app's drag conventions: feedback rendered
/// larger, the source ghosted to 0.3 while dragging.
class _TrayTile extends StatelessWidget {
  final Avatar avatar;
  final bool selected;
  final VoidCallback onTap;

  const _TrayTile({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(3),
        // Fill the grid cell minus the selection-ring padding.
        child: LayoutBuilder(
          builder: (context, c) =>
              AvatarArtwork(avatar: avatar, size: c.maxWidth),
        ),
      ),
    );

    return LongPressDraggable<Avatar>(
      data: avatar,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-48, -48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AvatarArtwork(avatar: avatar, size: 96),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }
}
