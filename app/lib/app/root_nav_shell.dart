import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../core/catalog/catalog_controller.dart';
import '../core/household/acting_user_controller.dart';
import '../core/subjects/character.dart';
import '../core/subjects/character_artwork.dart';
import '../core/subjects/subject.dart';
import '../core/subjects/subjects_controller.dart';
import '../features/profile/avatar_artwork.dart';
import '../l10n/l10n.dart';
import '../router/routes.dart';
import '../widgets/dashed_circle_painter.dart';

/// Hosts the four bottom-nav tabs (Home / Things / Awards / You) in a
/// swipeable PageView - swipe left/right between tabs, or tap the bar - with a
/// centre-docked quick-add-chore FAB over a notched bar (picks the thing first,
/// then opens New Chore). Adding a *thing* still lives in the Things tab's
/// AppBar (+).
///
/// Wired by `app_router.dart` via a custom [StatefulShellRoute] whose
/// `navigatorContainerBuilder` passes every branch Navigator in
/// [children]; pushing onto a branch (`context.push('/subject/123')`)
/// replaces the shell entirely until the pushed route is popped.
class RootNavShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;

  /// One Navigator per branch, same order as the bottom-bar tabs.
  final List<Widget> children;

  const RootNavShell({super.key, required this.shell, required this.children});

  @override
  ConsumerState<RootNavShell> createState() => _RootNavShellState();
}

class _RootNavShellState extends ConsumerState<RootNavShell> {
  // All solid glyphs: there's no hollow paw in any icon font, so the
  // other three match it rather than the paw sticking out. Built per
  // build because the labels are localized.
  List<_NavItem> _items(BuildContext context) => [
    _NavItem(label: context.l10n.navHome, icon: Icons.home, path: Routes.home),
    _NavItem(
      label: context.l10n.navThings,
      icon: Icons.pets,
      path: Routes.subjectsTab,
    ),
    _NavItem(
      label: context.l10n.navAwards,
      icon: Icons.emoji_events,
      path: Routes.historyTab,
    ),
    _NavItem(
      label: context.l10n.youTabTitle,
      icon: Icons.person,
      path: Routes.youTab,
    ),
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

  /// Quick-add a chore from the central FAB. A chore needs a subject, so pick
  /// the thing first: none → add a thing; otherwise a bottom sheet of
  /// character tiles (even with one, so it's clear who the chore is for),
  /// then the form for whichever was tapped.
  Future<void> _quickAddChore() async {
    final subjects =
        ref.read(subjectsControllerProvider).valueOrNull ?? const <Subject>[];
    if (subjects.isEmpty) {
      context.push(Routes.subjectNew);
      return;
    }
    final picked = await showModalBottomSheet<Subject>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SubjectPickerSheet(subjects: subjects),
    );
    if (picked != null && mounted) {
      context.push(Routes.choreNew(picked.id));
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _quickAddChore,
        tooltip: context.l10n.navAddChore,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        items: _items(context),
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
      // Carve a notch for the centre-docked add-a-chore FAB; the tabs split
      // 2 + 2 around a fixed centre gap so they stay clear of it.
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _tab(0, scheme),
            _tab(1, scheme),
            const SizedBox(width: 56),
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
    final item = items[i];
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 32,
        // The You tab shows the acting identity's avatar + name instead of a
        // static glyph (red-ringed, and named, when acting as someone else).
        child: item.path == Routes.youTab
            ? _YouTab(isSelected: isSelected, baseColor: color)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The You tab: the currently-acting identity's avatar with its name below.
/// A red ring + the member's name (instead of "You") mark that you're acting
/// as someone else; otherwise it's your own avatar and the primary selection
/// ring. The avatar is deliberately larger than the sibling glyphs.
class _YouTab extends ConsumerWidget {
  final bool isSelected;
  final Color baseColor;
  const _YouTab({required this.isSelected, required this.baseColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final actingMember = ref.watch(actingMemberProvider).valueOrNull;
    final myUserId = auth?.userId;
    final isOther = actingMember != null && actingMember.userId != myUserId;

    // Fall back to the signed-in user's own avatar when acting as self (or
    // before the acting member resolves).
    final avatarId = isOther ? actingMember.avatar : auth?.avatar;
    final avatar = ref.watch(catalogProvider).lookupAvatar(avatarId);
    final ringColor = isOther
        ? Colors.red
        : (isSelected ? scheme.primary : Colors.transparent);
    final label = isOther ? actingMember.displayName : context.l10n.youTabTitle;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2),
          ),
          child: AvatarArtwork(avatar: avatar, size: 34),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isOther ? Colors.red : baseColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing the household's things as character tiles, shown by
/// the central FAB when there's more than one. Tapping a tile pops the sheet
/// with that subject; the shell then opens its New Chore form.
class _SubjectPickerSheet extends StatelessWidget {
  final List<Subject> subjects;
  const _SubjectPickerSheet({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.navAddChoreFor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final s in subjects)
                  _SubjectTile(
                    subject: s,
                    onTap: () => Navigator.pop(context, s),
                  ),
                _NewThingTile(
                  onTap: () {
                    // Capture the router before popping the sheet, then open
                    // the New thing page.
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push(Routes.subjectNew);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing in the picker sheet: its character on a circular stage with the
/// name underneath. Tap to choose it.
class _SubjectTile extends ConsumerWidget {
  final Subject subject;
  final VoidCallback onTap;
  const _SubjectTile({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final character = ref.watch(catalogProvider).lookupCharacter(subject.icon);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: ColoredBox(
                  color: character.stageColor,
                  child: CharacterArtwork(
                    character: character,
                    expression: CharacterExpression.idle,
                    stage: false,
                    iconSize: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing "New thing" target in the picker sheet - a dashed circle with a
/// plus, sized like the subject tiles, that opens the New thing page.
class _NewThingTile extends StatelessWidget {
  final VoidCallback onTap;
  const _NewThingTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: accent),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(Icons.add, size: 28, color: accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.editSubjectNewTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
