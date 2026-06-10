import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/completions/awards_controller.dart';
import '../../core/profile/avatar.dart';
import '../../core/profile/avatars.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../../widgets/dashed_circle_painter.dart';
import 'avatar_artwork.dart';

/// "You" bottom-nav branch: a polished profile + settings landing surface.
/// Edit lives in [EditProfileScreen]; this surface just summarises and
/// hosts the global log-out.
class YouTabScreen extends ConsumerWidget {
  const YouTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authControllerProvider).valueOrNull;

    final name = auth?.displayName ?? '';
    final email = auth?.email ?? '';
    final avatar = AvatarRegistry.lookup(auth?.avatar);

    return Scaffold(
      appBar: AppBar(title: const Text('You'), centerTitle: true),
      // Logout card pinned beneath the scrolling content so it's always
      // reachable without scrolling past the awards shelf.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push(Routes.profile),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AvatarArtwork(avatar: avatar, size: 144),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name.isEmpty ? '(no name set)' : name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (auth != null) _MyAwardsCard(myUserId: auth.userId),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_horiz),
                        SizedBox(width: 12),
                        Text('Switch household'),
                      ],
                    ),
                    onTap: () => context.push(Routes.householdPicker),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _LogoutCard(
              avatar: avatar,
              name: name.isEmpty ? 'You' : name,
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

/// Drag-to-log-out card, mirroring the household members' drag-to-leave
/// mechanic: your avatar chip on the left, a dashed red drop circle on
/// the right. Long-press the avatar, carry it into the circle, gone.
/// The deliberate gesture *is* the confirmation — no dialog.
class _LogoutCard extends StatelessWidget {
  final Avatar? avatar;
  final String name;
  final VoidCallback onLogout;

  const _LogoutCard({
    required this.avatar,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip({required double size}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarArtwork(avatar: avatar, size: size),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final restingChip = chip(size: 56);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LongPressDraggable<bool>(
              data: true,
              feedback: Material(
                color: Colors.transparent,
                child: chip(size: 72),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
              child: restingChip,
            ),
            DragTarget<bool>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (_) => onLogout(),
              builder: (context, candidate, _) {
                final hovering = candidate.isNotEmpty;
                final red = hovering ? Colors.red : Colors.red.shade300;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      painter: DashedCirclePainter(
                        color: red,
                        filled: hovering,
                      ),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.logout,
                          size: 24,
                          color: hovering ? Colors.white : red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Log out',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Card listing every weekly award the signed-in user currently holds —
/// the personality awards plus any character-given ones. Quiet "nothing
/// yet" line when the trophy shelf is empty.
class _MyAwardsCard extends ConsumerWidget {
  final String? myUserId;

  const _MyAwardsCard({required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final awards = ref.watch(weeklyAwardsProvider);

    final mine = [
      for (final a in awards.memberAwards)
        if (a.winnerUserId == myUserId) a,
    ];
    final mineFromCharacters = [
      for (final a in awards.characterAwards)
        if (a.winnerUserId == myUserId) a,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your awards this week',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (mine.isEmpty && mineFromCharacters.isEmpty)
              Text(
                'Nothing yet — plenty of week left!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              for (final a in mineFromCharacters) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: ClipOval(
                        child: CharacterArtwork(
                          character: CharacterRegistry.lookup(a.characterId),
                          stage: true,
                          iconSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${a.subjectName}'s ${a.title}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              for (final a in mine) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        a.emoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
