import 'package:flutter/material.dart';

import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';

/// Carousel-style picker for subject characters. Mirror of `PicturePicker`
/// used on household details - one character is centred at a time, with
/// neighbours peeking + faded on either side. Swipe (or tap a peeking
/// neighbour) to scroll; selection happens on settle.
///
/// Pass [selected] (nullable for "no pick yet") and receive a non-null
/// character id via [onChanged] whenever a new page settles.
class CharacterCarousel extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const CharacterCarousel({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<CharacterCarousel> createState() => _CharacterCarouselState();
}

class _CharacterCarouselState extends State<CharacterCarousel> {
  static const _viewportFraction = 0.6;
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
    for (var i = 0; i < CharacterRegistry.all.length; i++) {
      if (CharacterRegistry.all[i].id == id) return i;
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant CharacterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defer jumpToPage to post-frame: jumpToPage fires onPageChanged
    // synchronously, which would call the parent's setState during build.
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
        itemCount: CharacterRegistry.all.length,
        onPageChanged: (i) {
          _currentIndex = i;
          widget.onChanged(CharacterRegistry.all[i].id);
        },
        itemBuilder: (context, i) {
          return _CarouselTile(
            character: CharacterRegistry.all[i],
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
  final Character character;
  final PageController controller;
  final int index;
  final VoidCallback onTap;

  const _CarouselTile({
    required this.character,
    required this.controller,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double offset;
        if (controller.position.hasContentDimensions) {
          offset =
              ((controller.page ?? controller.initialPage.toDouble()) - index)
                  .abs();
        } else {
          offset = (controller.initialPage - index).abs().toDouble();
        }
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DecoratedBox(
            // Gentle lift off the page; radius matches the artwork's
            // stage panel so the shadow hugs its corners.
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
            child: CharacterArtwork(character: character),
          ),
        ),
      ),
    );
  }
}
