import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';

/// Hosts the four bottom-nav tabs (Home / Subjects / History / You) on top
/// of a central + FAB. The FAB is docked in a notch on the bottom bar and
/// pushes the new-subject flow.
///
/// Wired by `app_router.dart` via `StatefulShellRoute.indexedStack` — each
/// branch's root route renders inside [child]; pushing onto a branch
/// (`context.push('/subject/123')`) replaces the shell entirely until the
/// pushed route is popped.
class RootNavShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const RootNavShell({super.key, required this.shell});

  static const _items = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.home_outlined, path: Routes.home),
    _NavItem(
        label: 'Friends',
        icon: Icons.pets_outlined,
        path: Routes.subjectsTab),
    _NavItem(
        label: 'Activities',
        icon: Icons.history,
        path: Routes.historyTab),
    _NavItem(
        label: 'You', icon: Icons.person_outline, path: Routes.youTab),
  ];

  void _goBranch(int index) {
    shell.goBranch(
      index,
      // Tap an already-active tab to reset that branch's stack to root.
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton(
        heroTag: 'rootFab',
        tooltip: 'Add friend',
        onPressed: () => context.push(Routes.subjectNew),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        items: _items,
        currentIndex: shell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
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
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _tab(0, scheme),
            _tab(1, scheme),
            // Spacer for the central FAB notch.
            const SizedBox(width: 64),
            _tab(2, scheme),
            _tab(3, scheme),
          ],
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
