import 'package:flutter/material.dart';

import '../../core/household/picture.dart';
import '../../core/household/pictures.dart';
import 'picture_artwork.dart';

/// Carousel-style picker for household pictures.
///
/// One picture is shown centred at a time; neighbours peek at the edges so
/// the swipe affordance is obvious. The currently-staged picture is whatever
/// is centred - selection happens by swiping, not tapping. Tapping a peeking
/// neighbour snaps to it.
///
/// Pass [selected] (nullable) and receive a non-null picture id via
/// [onChanged] whenever a new page settles.
class PicturePicker extends StatefulWidget {
  /// Currently-selected picture id. Null = no picture chosen yet -
  /// carousel opens at the first entry.
  final String? selected;

  final ValueChanged<String> onChanged;

  const PicturePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<PicturePicker> createState() => _PicturePickerState();
}

class _PicturePickerState extends State<PicturePicker> {
  static const _viewportFraction = 0.75;
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialIndex();
    _controller = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
  }

  int _initialIndex() {
    final id = widget.selected;
    if (id == null) return 0;
    for (var i = 0; i < PictureRegistry.all.length; i++) {
      if (PictureRegistry.all[i].id == id) return i;
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant PicturePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Honour external changes (e.g. a different household loaded under
    // us) by jumping silently. Deferred to a post-frame callback because
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
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _controller,
        itemCount: PictureRegistry.all.length,
        onPageChanged: (i) {
          _currentIndex = i;
          widget.onChanged(PictureRegistry.all[i].id);
        },
        itemBuilder: (context, i) {
          return _CarouselTile(
            picture: PictureRegistry.all[i],
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
  final Picture picture;
  final PageController controller;
  final int index;
  final VoidCallback onTap;

  const _CarouselTile({
    required this.picture,
    required this.controller,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Distance from this tile's index to the centred page.
        // Before the controller is attached, fall back to initialPage.
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
        // Further away clamps to the same.
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DecoratedBox(
            // Gentle lift off the page, matching the other pickers.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PictureArtwork(picture: picture, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
