import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/household/households_controller.dart';
import '../../core/profile/avatars.dart';
import '../../router/routes.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../../widgets/labeled_field.dart';
import '../profile/avatar_artwork.dart';
import 'picture_picker.dart';

/// View / edit one household the user is a member of.
class HouseholdDetailsScreen extends ConsumerWidget {
  final String householdId;
  const HouseholdDetailsScreen({super.key, required this.householdId});

  Household? _findHousehold(List<Household> households) {
    for (final h in households) {
      if (h.id == householdId) return h;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHouseholds = ref.watch(householdsControllerProvider);

    return asyncHouseholds.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Household')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (households) {
        final household = _findHousehold(households);
        if (household == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Household')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "You're no longer a member of this household.",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(household.name),
            actions: [
              if (household.isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete household',
                  onPressed: () =>
                      _confirmAndDelete(context, ref, household),
                ),
            ],
          ),
          body: _Body(household: household),
        );
      },
    );
  }
}

Future<void> _confirmAndDelete(
    BuildContext context, WidgetRef ref, Household household) async {
  final confirmed = await _confirm(
    context,
    title: 'Delete ${household.name}?',
    body: 'All subjects, chores and history for this household will be '
        'permanently removed for everyone in it. This cannot be undone.',
    action: 'Delete',
  );
  if (!confirmed) return;
  try {
    await ref
        .read(householdActionsProvider)
        .deleteHousehold(householdId: household.id);
    if (context.mounted) context.go(Routes.home);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('$e'),
      ));
    }
  }
}

Future<void> _confirmAndLeave(
    BuildContext context, WidgetRef ref, Household household) async {
  final confirmed = await _confirm(
    context,
    title: 'Leave ${household.name}?',
    body: "You won't see this household's chores or completions any more. "
        'You can re-join later with an invite code.',
    action: 'Leave',
  );
  if (!confirmed) return;
  try {
    await ref
        .read(householdActionsProvider)
        .leaveHousehold(membershipId: household.membershipId);
    if (context.mounted) context.go(Routes.home);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('$e'),
      ));
    }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _Body extends ConsumerStatefulWidget {
  final Household household;
  const _Body({required this.household});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _nameCtrl = TextEditingController();
  String _seededName = '';
  String? _stagedPicture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.household.name;
    _seededName = widget.household.name;
    _stagedPicture = widget.household.picture;
  }

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the household's name changed under us (e.g. another member
    // renamed it and a refresh brought the new value in) — and the user
    // isn't mid-edit on the field — re-seed.
    if (widget.household.name != oldWidget.household.name &&
        _nameCtrl.text == _seededName) {
      _nameCtrl.text = widget.household.name;
      _seededName = widget.household.name;
    }
    // Same for picture: if it changed under us and we're not mid-edit
    // (i.e. our staged value matches the previous server value), re-seed.
    if (widget.household.picture != oldWidget.household.picture &&
        _stagedPicture == oldWidget.household.picture) {
      _stagedPicture = widget.household.picture;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isNameDirty {
    final trimmed = _nameCtrl.text.trim();
    return trimmed.isNotEmpty && trimmed != widget.household.name;
  }

  bool get _isPictureDirty => _stagedPicture != widget.household.picture;

  bool get _isDirty => _isNameDirty || _isPictureDirty;

  Future<void> _save() async {
    if (!_isDirty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final newName = _nameCtrl.text.trim();
    try {
      await ref.read(householdActionsProvider).updateHousehold(
            householdId: widget.household.id,
            name: _isNameDirty ? newName : null,
            picture: _isPictureDirty ? (_stagedPicture ?? '') : null,
          );
      if (_isNameDirty) _seededName = newName;
      // Save succeeded → drop the user back on home.
      if (mounted) router.go(Routes.home);
    } on ClientException catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text(e.response['message'] as String? ?? 'Save failed'),
      ));
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('$e'),
      ));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.household;
    final isOwner = h.isOwner;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(householdMembersControllerProvider(h.id));
        await ref
            .read(householdMembersControllerProvider(h.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Picture carousel — staged selection only; written to PB by
          // the Save changes button along with any name edit. Picture is
          // editable by everyone (kids included); name stays owner-only.
          IgnorePointer(
            ignoring: _busy,
            child: PicturePicker(
              selected: _stagedPicture,
              onChanged: (pictureId) =>
                  setState(() => _stagedPicture = pictureId),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Household name',
                    child: TextField(
                      controller: _nameCtrl,
                      enabled: isOwner && !_busy,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (isOwner && _isDirty) _save();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Save changes'),
                    onPressed: (_isDirty && !_busy) ? _save : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InviteSettings(household: h),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Members',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _MembersList(
                    household: h,
                    viewerIsOwner: isOwner,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteSettings extends ConsumerStatefulWidget {
  final Household household;
  const _InviteSettings({required this.household});

  @override
  ConsumerState<_InviteSettings> createState() => _InviteSettingsState();
}

class _InviteSettingsState extends ConsumerState<_InviteSettings> {
  bool _busy = false;

  Future<void> _toggle(bool open) async {
    setState(() => _busy = true);
    try {
      await ref.read(householdActionsProvider).setInvitesOpen(
            householdId: widget.household.id,
            open: open,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text('$e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(householdActionsProvider)
          .rotateInviteCode(widget.household.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text('$e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the system share sheet with the invite code. The sheet's own
  /// "Copy" action covers the old copy-to-clipboard behaviour.
  Future<void> _share(String code) async {
    await Share.share(
      'Join our household on Have You Fed The Dog? '
      'Open the app and enter invite code $code',
      subject: 'Have You Fed The Dog? — household invite',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOwner = widget.household.isOwner;
    final isOpen = widget.household.invitesOpen;
    final code = widget.household.inviteCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_add_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite someone',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Invite family or flatmates',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOpen ? 'Invites are on' : 'Invites are off',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: isOpen,
                        onChanged: (isOwner && !_busy) ? _toggle : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOpen && code != null) ...[
              const SizedBox(height: 20),
              Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Live until you turn invites off',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share code'),
                  onPressed: _busy ? null : () => _share(code),
                ),
              ),
              if (isOwner)
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate new code'),
                  onPressed: _busy ? null : _rotate,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  final Household household;
  final bool viewerIsOwner;
  const _MembersList({required this.household, required this.viewerIsOwner});

  Future<void> _kick(
    BuildContext context,
    WidgetRef ref,
    HouseholdMember m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${m.displayName}?'),
        content: Text(
          '${m.displayName} will lose access to this household immediately. '
          'They can re-join later with an invite code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(householdActionsProvider).kickMember(
            membershipId: m.membershipId,
            householdId: household.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text('$e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMembers =
        ref.watch(householdMembersControllerProvider(household.id));
    final myUserId =
        ref.watch(authControllerProvider).valueOrNull?.userId;

    return asyncMembers.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load members: $e'),
        ),
      ),
      data: (members) {
        // One mechanism for everyone: owners drag *others* into the bin
        // to remove them; non-owners drag *themselves* in to leave. An
        // owner can't drag their own chip — to step away they delete the
        // household.
        final otherCount =
            members.where((m) => m.userId != myUserId).length;
        final showBin = viewerIsOwner ? otherCount > 0 : true;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: [
            for (final m in members)
              _MemberChip(
                member: m,
                isMe: m.userId == myUserId,
                canDrag: viewerIsOwner
                    ? m.userId != myUserId
                    : m.userId == myUserId,
              ),
            if (showBin)
              Builder(builder: (binContext) {
                return _RemoveBinChip(
                  label: viewerIsOwner ? 'Remove' : 'Leave',
                  onDrop: (m) => m.userId == myUserId
                      ? _confirmAndLeave(binContext, ref, household)
                      : _kick(binContext, ref, m),
                );
              }),
          ],
        );
      },
    );
  }
}

/// Drop target for removing a member — a ghosted dashed red circle with a
/// bin icon, sized and labelled like a member chip so it reads as part of
/// the cloud. Fills solid red while a dragged avatar hovers over it.
class _RemoveBinChip extends StatelessWidget {
  final ValueChanged<HouseholdMember> onDrop;

  /// Caption under the circle — "Remove" for owners kicking others,
  /// "Leave" for a member dragging themselves out.
  final String label;

  const _RemoveBinChip({required this.onDrop, this.label = 'Remove'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<HouseholdMember>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final red = hovering ? Colors.red : Colors.red.shade300;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: red, filled: hovering),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.delete_outline,
                  size: 24,
                  color: hovering ? Colors.white : red,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 80,
              child: Text(
                label,
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
    );
  }
}

/// One avatar in the members cloud: avatar circle, name underneath,
/// "(you)" suffix on self. Wrapped in [Draggable] when the viewer can
/// kick this member.
class _MemberChip extends StatelessWidget {
  final HouseholdMember member;
  final bool isMe;
  final bool canDrag;

  const _MemberChip({
    required this.member,
    required this.isMe,
    required this.canDrag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = AvatarRegistry.lookup(member.avatar);
    final label = isMe ? '${member.displayName} (you)' : member.displayName;

    Widget chip({required double avatarSize}) {
      Widget avatarWidget = AvatarArtwork(avatar: avatar, size: avatarSize);
      if (member.isOwner) {
        avatarWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            avatarWidget,
            Positioned(
              right: -6,
              bottom: -2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.star,
                    size: 12, color: scheme.onPrimary),
              ),
            ),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatarWidget,
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (member.isOwner)
            Text(
              'Owner',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      );
    }

    final restingChip = chip(avatarSize: 56);
    if (!canDrag) return restingChip;

    // Long-press to lift — a plain Draggable claims the gesture arena
    // immediately, which makes the page hard to scroll when a thumb
    // lands on an avatar.
    return LongPressDraggable<HouseholdMember>(
      data: member,
      feedback: Material(
        color: Colors.transparent,
        child: chip(avatarSize: 72),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
      child: restingChip,
    );
  }
}
