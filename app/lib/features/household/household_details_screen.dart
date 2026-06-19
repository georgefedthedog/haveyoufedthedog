import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/household/households_controller.dart';
import '../../router/routes.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../../widgets/drop_target_circle.dart';
import '../../widgets/labeled_field.dart';
import '../profile/avatar_artwork.dart';
import '../profile/avatar_picker.dart';
import '../store/browse_packs_button.dart';
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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
                  onPressed: () => _confirmAndDelete(context, ref, household),
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
  BuildContext context,
  WidgetRef ref,
  Household household,
) async {
  final confirmed = await _confirm(
    context,
    title: 'Delete ${household.name}?',
    body:
        'All subjects, chores and history for this household will be '
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
    }
  }
}

Future<void> _confirmAndLeave(
  BuildContext context,
  WidgetRef ref,
  Household household,
) async {
  final confirmed = await _confirm(
    context,
    title: 'Leave ${household.name}?',
    body:
        "You won't see this household's chores or completions any more. "
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
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
  final _residentsCtrl = TextEditingController();
  String _seededName = '';
  String _seededResidents = '';
  String? _stagedPicture;
  bool _busy = false;

  /// The phone's IANA zone - used to offer a one-tap fix when it differs
  /// from the household's stored zone.
  String? _phoneTz;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.household.name;
    _seededName = widget.household.name;
    _residentsCtrl.text = widget.household.residents ?? '';
    _seededResidents = widget.household.residents ?? '';
    _stagedPicture = widget.household.picture;
    FlutterTimezone.getLocalTimezone()
        .then((tz) {
          if (mounted) setState(() => _phoneTz = tz);
        })
        .catchError((_) {});
  }

  Future<void> _setTimezoneToPhone() async {
    final tz = _phoneTz;
    if (tz == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(householdActionsProvider)
          .updateHousehold(householdId: widget.household.id, timezone: tz);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the household's name changed under us (e.g. another member
    // renamed it and a refresh brought the new value in) - and the user
    // isn't mid-edit on the field - re-seed.
    if (widget.household.name != oldWidget.household.name &&
        _nameCtrl.text == _seededName) {
      _nameCtrl.text = widget.household.name;
      _seededName = widget.household.name;
    }
    // Same for residents.
    final residents = widget.household.residents ?? '';
    if (residents != (oldWidget.household.residents ?? '') &&
        _residentsCtrl.text == _seededResidents) {
      _residentsCtrl.text = residents;
      _seededResidents = residents;
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
    _residentsCtrl.dispose();
    super.dispose();
  }

  bool get _isNameDirty {
    final trimmed = _nameCtrl.text.trim();
    return trimmed.isNotEmpty && trimmed != widget.household.name;
  }

  // Unlike the name, residents may be cleared - empty is a valid value.
  bool get _isResidentsDirty =>
      _residentsCtrl.text.trim() != (widget.household.residents ?? '');

  bool get _isPictureDirty => _stagedPicture != widget.household.picture;

  bool get _isDirty => _isNameDirty || _isResidentsDirty || _isPictureDirty;

  Future<void> _save() async {
    if (!_isDirty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final newName = _nameCtrl.text.trim();
    try {
      await ref
          .read(householdActionsProvider)
          .updateHousehold(
            householdId: widget.household.id,
            name: _isNameDirty ? newName : null,
            residents: _isResidentsDirty ? _residentsCtrl.text.trim() : null,
            picture: _isPictureDirty ? (_stagedPicture ?? '') : null,
          );
      if (_isNameDirty) _seededName = newName;
      if (_isResidentsDirty) _seededResidents = _residentsCtrl.text.trim();
      // Save succeeded → drop the user back on home.
      if (mounted) router.go(Routes.home);
    } on ClientException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(e.response['message'] as String? ?? 'Save failed'),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
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
        await ref.read(householdMembersControllerProvider(h.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          // Picture carousel - staged selection only; written to PB by
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
          const BrowsePacksButton(label: 'Get more homes'),
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
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Who lives here?',
                    child: TextField(
                      controller: _residentsCtrl,
                      enabled: isOwner && !_busy,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'The Goodchilds',
                      ),
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
                  const SizedBox(height: 10),
                  // The household's clock - overdue nudges are timed
                  // against this. Offer a one-tap fix when this phone
                  // disagrees (wrong capture, or the family moved).
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final scheme = theme.colorScheme;
                      final tz = h.timezone ?? 'Europe/London';
                      final mismatch =
                          isOwner && _phoneTz != null && _phoneTz != h.timezone;
                      return Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Timezone: $tz',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (mismatch)
                            TextButton(
                              onPressed: _busy ? null : _setTimezoneToPhone,
                              child: const Text("Use this phone's"),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Who lives here?" label when set ("The Goodchilds"),
                  // plain 'Members' otherwise. The getter already maps
                  // blank to null.
                  Text(
                    h.residents ?? 'Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _MembersList(household: h, viewerIsOwner: isOwner),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InviteSettings(household: h),
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
      await ref
          .read(householdActionsProvider)
          .setInvitesOpen(householdId: widget.household.id, open: open);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
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
      subject: 'Have You Fed The Dog? - household invite',
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
                      Text(
                        'Invite someone',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live until you turn invites off',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _MembersList extends ConsumerStatefulWidget {
  final Household household;
  final bool viewerIsOwner;
  const _MembersList({required this.household, required this.viewerIsOwner});

  @override
  ConsumerState<_MembersList> createState() => _MembersListState();
}

class _MembersListState extends ConsumerState<_MembersList> {
  /// The member currently being long-press dragged, or null. While non-null
  /// the Add slot morphs into the Remove bin (same as the manage-chores
  /// cloud), labelled for the dragged member; no bin is shown otherwise.
  HouseholdMember? _draggingMember;

  /// Create (existing == null) or edit a phone-less managed member. A pushed
  /// screen (not a GoRoute) mirroring Edit Profile's layout.
  Future<void> _openMemberEditor({HouseholdMember? existing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ManagedMemberScreen(
          householdId: widget.household.id,
          existing: existing,
        ),
      ),
    );
  }

  /// Managed members are deleted outright (the loginless user), not just
  /// unlinked - so the bin routes them here instead of [_kick].
  Future<void> _deleteManaged(
    BuildContext context,
    WidgetRef ref,
    HouseholdMember m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${m.displayName}?'),
        content: Text(
          '${m.displayName} has no phone of their own, so this removes them '
          'completely. Their past completions still count but will show as '
          '"Someone".',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(householdActionsProvider)
          .deleteManagedMember(
            householdId: widget.household.id,
            userId: m.userId,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
      }
    }
  }

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
      await ref
          .read(householdActionsProvider)
          .kickMember(
            membershipId: m.membershipId,
            householdId: widget.household.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMembers = ref.watch(
      householdMembersControllerProvider(widget.household.id),
    );
    final myUserId = ref.watch(authControllerProvider).valueOrNull?.userId;

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
        // owner can't drag their own chip - to step away they delete the
        // household. The bin only appears while a chip is being dragged.
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: [
            for (final m in members)
              _MemberChip(
                member: m,
                isMe: m.userId == myUserId,
                canDrag: widget.viewerIsOwner
                    ? m.userId != myUserId
                    : m.userId == myUserId,
                // Owners tap a managed member to edit their name/avatar.
                onTap: (widget.viewerIsOwner && m.isManaged)
                    ? () => _openMemberEditor(existing: m)
                    : null,
                onDragChanged: (member) =>
                    setState(() => _draggingMember = member),
              ),
            // While dragging, the Add slot becomes the Remove bin, labelled
            // for what's being dragged; otherwise owners see Add and
            // non-owners see nothing.
            if (_draggingMember != null)
              Builder(
                builder: (binContext) {
                  final dragged = _draggingMember!;
                  final label = dragged.userId == myUserId
                      ? 'Leave'
                      : dragged.isManaged
                      ? 'Delete'
                      : 'Remove';
                  return _RemoveBinChip(
                    label: label,
                    onDrop: (m) {
                      if (m.userId == myUserId) {
                        _confirmAndLeave(binContext, ref, widget.household);
                      } else if (m.isManaged) {
                        // Phone-less members are deleted outright, not unlinked.
                        _deleteManaged(binContext, ref, m);
                      } else {
                        _kick(binContext, ref, m);
                      }
                    },
                  );
                },
              )
            else if (widget.viewerIsOwner)
              _AddMemberChip(onTap: () => _openMemberEditor()),
          ],
        );
      },
    );
  }
}

/// Drop target for removing a member - a ghosted dashed red circle with a
/// bin icon, sized and labelled like a member chip so it reads as part of
/// the cloud. Fills solid red while a dragged avatar hovers over it.
class _RemoveBinChip extends StatelessWidget {
  final ValueChanged<HouseholdMember> onDrop;

  /// Caption under the circle - "Remove" for owners kicking others,
  /// "Leave" for a member dragging themselves out.
  final String label;

  const _RemoveBinChip({required this.onDrop, this.label = 'Remove'});

  @override
  Widget build(BuildContext context) {
    return DropTargetCircle<HouseholdMember>(
      icon: Icons.delete_outline,
      label: label,
      baseColor: Colors.red.shade300,
      hoverColor: Colors.red,
      labelWidth: 80,
      onDrop: onDrop,
    );
  }
}

/// A small circular corner badge (owner star, no-phone marker, or red remove
/// cross) overlaid on a member avatar.
Widget _cornerBadge(IconData icon, Color bg, Color fg) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg,
      border: Border.all(color: Colors.white, width: 2),
    ),
    padding: const EdgeInsets.all(4),
    child: Icon(icon, size: 12, color: fg),
  );
}

/// One avatar in the members cloud: avatar circle, name underneath,
/// "(you)" suffix on self. Wrapped in [Draggable] when the viewer can
/// kick this member.
class _MemberChip extends ConsumerWidget {
  final HouseholdMember member;
  final bool isMe;
  final bool canDrag;

  /// Tapping the chip (owners, on a managed member) - opens the edit screen.
  final VoidCallback? onTap;

  /// Fired with this member when a long-press drag lifts the chip, null when
  /// it ends. The parent swaps the Add slot for a Remove bin (labelled for the
  /// dragged member) while a drag is live.
  final ValueChanged<HouseholdMember?>? onDragChanged;

  const _MemberChip({
    required this.member,
    required this.isMe,
    required this.canDrag,
    this.onTap,
    this.onDragChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = ref.watch(catalogProvider).lookupAvatar(member.avatar);
    final label = isMe ? '${member.displayName} (you)' : member.displayName;

    // Corner badge: a red cross while being dragged to the bin (matches the
    // manage-chores chip), else an owner star or a phone-less marker.
    Widget? badgeFor(bool removing) {
      if (removing) return _cornerBadge(Icons.close, Colors.red, Colors.white);
      if (member.isOwner) {
        return _cornerBadge(Icons.star, scheme.primary, scheme.onPrimary);
      }
      if (member.isManaged) {
        return _cornerBadge(
          Icons.mobile_off,
          scheme.secondary,
          scheme.onSecondary,
        );
      }
      return null;
    }

    Widget chip({required double avatarSize, bool removing = false}) {
      Widget avatarWidget = AvatarArtwork(avatar: avatar, size: avatarSize);
      final badge = badgeFor(removing);
      if (badge != null) {
        avatarWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            avatarWidget,
            Positioned(right: -6, bottom: -2, child: badge),
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

    Widget result;
    if (!canDrag) {
      result = restingChip;
    } else {
      // Long-press to lift - a plain Draggable claims the gesture arena
      // immediately, which makes the page hard to scroll when a thumb
      // lands on an avatar.
      result = LongPressDraggable<HouseholdMember>(
        data: member,
        onDragStarted: () => onDragChanged?.call(member),
        onDragEnd: (_) => onDragChanged?.call(null),
        // The lifted copy swaps its badge for a red cross - you're carrying it
        // toward the bin, not editing it.
        feedback: Material(
          color: Colors.transparent,
          child: chip(avatarSize: 72, removing: true),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
        child: restingChip,
      );
    }

    // Tap (distinct from the long-press drag) opens the edit sheet.
    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }
    return result;
  }
}

/// "Add a phone-less member" affordance in the members cloud (owners only):
/// a dashed circle with a +, sized and captioned like a member chip.
class _AddMemberChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMemberChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter: DashedCirclePainter(color: scheme.primary, filled: false),
              child: Icon(Icons.add, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              'Add',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create or edit a phone-less managed member. Mirrors the Edit Profile
/// screen's layout: avatar picker on top, then a card with a "Display name"
/// field and the Save button. Create when [existing] is null, otherwise edit
/// that member. Deletion is via dragging the chip to the bin, not here.
class _ManagedMemberScreen extends ConsumerStatefulWidget {
  final String householdId;
  final HouseholdMember? existing;
  const _ManagedMemberScreen({required this.householdId, this.existing});

  @override
  ConsumerState<_ManagedMemberScreen> createState() =>
      _ManagedMemberScreenState();
}

class _ManagedMemberScreenState extends ConsumerState<_ManagedMemberScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _avatar;
  String _baselineName = '';
  String? _baselineAvatar;
  bool _seeded = false;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Anything changed vs the seeded baseline? Opening the screen shouldn't
  /// count as a change (same contract as Edit Profile).
  bool get _isDirty =>
      _nameCtrl.text.trim() != _baselineName || _avatar != _baselineAvatar;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final actions = ref.read(householdActionsProvider);
    final name = _nameCtrl.text.trim();
    try {
      if (_isEdit) {
        await actions.updateManagedMember(
          householdId: widget.householdId,
          userId: widget.existing!.userId,
          name: name,
          avatar: _avatar ?? '',
        );
      } else {
        await actions.createManagedMember(
          householdId: widget.householdId,
          name: name,
          avatar: _avatar,
        );
      }
      if (mounted) nav.pop();
    } on ClientException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(e.response['message'] as String? ?? 'Save failed'),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not save: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Delete this managed member (edit mode only), with a confirm. On success
  /// pops back to the household. Mirrors the bin-drop deletion.
  Future<void> _delete() async {
    final m = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${m.displayName}?'),
        content: Text(
          '${m.displayName} has no phone of their own, so this removes them '
          'completely. Their past completions still count but will show as '
          '"Someone".',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref
          .read(householdActionsProvider)
          .deleteManagedMember(householdId: widget.householdId, userId: m.userId);
      if (mounted) nav.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('Could not delete: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seed once. Avatar baseline falls back to the first selectable avatar
    // (the picker opens with it on the stage) so a no-touch save stores
    // what's visibly selected - mirrors Edit Profile.
    if (!_seeded) {
      final avatars = ref.read(selectableCatalogProvider).avatars;
      final fallback = avatars.isNotEmpty ? avatars.first.id : null;
      _baselineName = widget.existing?.displayName ?? '';
      _baselineAvatar = widget.existing?.avatar ?? fallback;
      _nameCtrl.text = _baselineName;
      _avatar = _baselineAvatar;
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit member' : 'Add member'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete member',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AbsorbPointer(
                absorbing: _busy,
                child: AvatarPicker(
                  selected: _avatar,
                  onChanged: (id) => setState(() => _avatar = id),
                ),
              ),
              const BrowsePacksButton(label: 'Get more avatars'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: 'Display name',
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'How this member appears to everyone',
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Save changes'),
                        onPressed: (_isDirty && !_busy) ? _save : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
