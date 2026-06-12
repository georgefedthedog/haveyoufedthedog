import 'package:flutter/material.dart';

/// In-page replacement for an AppBar title on the nav-shell tabs: same
/// Knewave 28 as `appBarTheme.titleTextStyle`, centred, but living inside
/// the page's scroll view so it scrolls out of the way with the content.
class PageTitle extends StatelessWidget {
  final String text;

  const PageTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56, // matches the AppBar it replaces
      child: Center(
        child: Text(text, style: Theme.of(context).appBarTheme.titleTextStyle),
      ),
    );
  }
}
