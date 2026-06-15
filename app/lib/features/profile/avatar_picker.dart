import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/profile/avatar.dart';
import 'avatar_artwork.dart';

/// Carousel-style picker for profile avatars. Mirror of `PicturePicker`
/// (households) - one avatar centred, neighbours peek + scale down so the
/// swipe affordance is obvious. Selection happens by swiping; tapping a
/// peeking neighbour snaps to it.
///
/// Pass [selected] (nullable) and receive a non-null avatar id via
/// [onChanged] whenever a new page settles.
class AvatarPicker extends ConsumerStatefulWidget {
  /// Currently-selected avatar id. Null = no avatar chosen yet - carousel
  /// opens at the first entry.
  final String? selected;

  final ValueChanged<String> onChanged;

  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  // Wide enough that the 180dp avatar never gets width-squeezed into an
  // ellipse on a ~390dp-wide phone, while neighbours still peek.
  static const _viewportFraction = 0.48;
  late final PageController _controller;
  late int _currentIndex;
  late List<Avatar> _avatars;

  @override
  void initState() {
    super.initState();
    _avatars = ref.read(selectableCatalogProvider).avatars;
    _currentIndex = _initialIndex();
    _controller = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
  }

  int _initialIndex() {
    final id = widget.selected;
    if (id == null) return 0;
    for (var i = 0; i < _avatars.length; i++) {
      if (_avatars[i].id == id) return i;
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant AvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Honour external changes (e.g. a different user loaded under us) by
    // jumping silently. Deferred to a post-frame callback because
    // jumpToPage fires onPageChanged synchronously, which would call the
    // parent's setState during build.
    if (widget.selected != oldWidget.selected) {
      final target = _initialIndex();
      if (target != _currentIndex) {
        _currentIndex = target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_controller.hasClients) _controller.jumpToPage(target);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remote catalog entries can land after first build (the merged list
    // only ever grows). Re-resolve the selected id's index when it does -
    // same deferred-jump dance as didUpdateWidget.
    final avatars = ref.watch(selectableCatalogProvider).avatars;
    if (avatars.length != _avatars.length) {
      _avatars = avatars;
      final target = _initialIndex();
      if (target != _currentIndex) {
        _currentIndex = target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_controller.hasClients) _controller.jumpToPage(target);
        });
      }
    } else {
      _avatars = avatars;
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _controller,
        itemCount: _avatars.length,
        onPageChanged: (i) {
          _currentIndex = i;
          widget.onChanged(_avatars[i].id);
        },
        itemBuilder: (context, i) {
          return _CarouselTile(
            avatar: _avatars[i],
            controller: _controller,
            index: i,
            onTap: () => _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            ),
          );
        },
      ),
    );
  }
}

class _CarouselTile extends StatelessWidget {
  final Avatar avatar;
  final PageController controller;
  final int index;
  final VoidCallback onTap;

  const _CarouselTile({
    required this.avatar,
    required this.controller,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Distance from this tile's index to the centred page. Before the
        // controller is attached, fall back to initialPage.
        double offset;
        if (controller.position.hasContentDimensions) {
          offset =
              ((controller.page ?? controller.initialPage.toDouble()) - index)
                  .abs();
        } else {
          offset = (controller.initialPage - index).abs().toDouble();
        }
        // Centre (offset 0) → full size + opaque.
        // 1 page away → 78% size + 45% opacity.
        final t = offset.clamp(0.0, 1.0);
        final scale = 1.0 - (t * 0.22);
        final opacity = 1.0 - (t * 0.55);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: DecoratedBox(
            // Gentle lift off the page, matching the other pickers.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // 168, not 180: leaves room in the 200-high page for the drop
            // shadow (extends ~8 up / ~16 down), which the PageView clips.
            child: AvatarArtwork(avatar: avatar, size: 168),
          ),
        ),
      ),
    );
  }
}
