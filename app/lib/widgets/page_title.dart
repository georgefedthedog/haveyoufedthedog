import 'package:flutter/material.dart';

/// In-page replacement for an AppBar title on the nav-shell tabs: same
/// Knewave 28 as `appBarTheme.titleTextStyle`, centred, but living inside
/// the page's scroll view so it scrolls out of the way with the content.
///
/// An optional [subtitle] renders a muted body-font line beneath the title;
/// when present the fixed AppBar-matching height is dropped so the block can
/// grow to fit the wrapped copy.
class PageTitle extends StatelessWidget {
  final String text;
  final String? subtitle;

  const PageTitle({super.key, required this.text, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(text, style: theme.appBarTheme.titleTextStyle);

    if (subtitle == null) {
      return SizedBox(
        height: 56, // matches the AppBar it replaces
        child: Center(child: title),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        children: [
          title,
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
