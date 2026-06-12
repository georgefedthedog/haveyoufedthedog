import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';

/// Hosts the four bottom-nav tabs (Home / Friends / Awards / You) in a
/// swipeable PageView - swipe left/right between tabs, or tap the bar.
/// Adding a friend lives in the Friends tab's AppBar (+), not a FAB.
///
/// Wired by `app_router.dart` via a custom [StatefulShellRoute] whose
/// `navigatorContainerBuilder` passes every branch Navigator in
/// [children]; pushing onto a branch (`context.push('/subject/123')`)
/// replaces the shell entirely until the pushed route is popped.
class RootNavShell extends StatefulWidget {
  final StatefulNavigationShell shell;

  /// One Navigator per branch, same order as the bottom-bar tabs.
  final List<Widget> children;

  const RootNavShell({super.key, required this.shell, required this.children});

  @override
  State<RootNavShell> createState() => _RootNavShellState();
}

class _RootNavShellState extends State<RootNavShell> {
  // All solid glyphs: there's no hollow paw in any icon font, so the
  // other three match it rather than the paw sticking out.
  static const _items = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.home, path: Routes.home),
    _NavItem(label: 'Friends', icon: Icons.pets, path: Routes.subjectsTab),
    _NavItem(
      label: 'Awards',
      icon: Icons.emoji_events,
      path: Routes.historyTab,
    ),
    _NavItem(label: 'You', icon: Icons.person, path: Routes.youTab),
  ];

  late final PageController _controller = PageController(
    initialPage: widget.shell.currentIndex,
  );

  @override
  void didUpdateWidget(covariant RootNavShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Branch changed from outside the PageView (tab tap, deep link) -
    // slide across to it. When the change originated from a swipe the
    // controller is already on the page and this is a no-op.
    final index = widget.shell.currentIndex;
    if (_controller.hasClients && _controller.page?.round() != index) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goBranch(int index) {
    widget.shell.goBranch(
      index,
      // Tap an already-active tab to reset that branch's stack to root.
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (i) {
          if (i != widget.shell.currentIndex) widget.shell.goBranch(i);
        },
        children: [
          for (final child in widget.children) _KeepAliveBranch(child: child),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        items: _items,
        currentIndex: widget.shell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}

/// Keeps an off-screen branch Navigator alive inside the PageView so tab
/// state (scroll positions, in-branch history) survives swiping away.
class _KeepAliveBranch extends StatefulWidget {
  final Widget child;
  const _KeepAliveBranch({required this.child});

  @override
  State<_KeepAliveBranch> createState() => _KeepAliveBranchState();
}

class _KeepAliveBranchState extends State<_KeepAliveBranch>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}

class _BottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [for (var i = 0; i < items.length; i++) _tab(i, scheme)],
        ),
      ),
    );
  }

  Widget _tab(int i, ColorScheme scheme) {
    final isSelected = currentIndex == i;
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(items[i].icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              items[i].label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
