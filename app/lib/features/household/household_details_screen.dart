import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/server_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/catalog/catalog_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/household/households_controller.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/confirm_by_typing.dart';
import '../../widgets/dashed_circle_painter.dart';
import '../../widgets/drop_target_circle.dart';
import '../../widgets/glow_highlight.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/wiggle.dart';
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
        appBar: AppBar(title: Text(context.l10n.householdTitle)),
        body: Center(child: Text(context.l10n.commonErrorDetails('$e'))),
      ),
      data: (households) {
        final household = _findHousehold(households);
        if (household == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.householdTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.householdNoLonger,
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
                  tooltip: context.l10n.householdDeleteTooltip,
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
  final confirmed = await confirmByTyping(
    context,
    title: context.l10n.commonDeleteTitle(household.name),
    body: context.l10n.householdDeleteBody,
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
    title: context.l10n.householdLeaveTitle(household.name),
    body: context.l10n.householdLeaveBody,
    action: context.l10n.householdLeave,
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
          child: Text(ctx.l10n.commonCancel),
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

/// Type-DELETE confirm for removing a managed member - shared by the members-
/// cloud bin and the Edit Member trash can (one copy, two entry points).
Future<bool> _confirmDeleteManaged(BuildContext context, String name) {
  return confirmByTyping(
    context,
    title: context.l10n.commonDeleteTitle(name),
    body: context.l10n.householdDeleteManagedBody(name),
  );
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
  final _scrollController = ScrollController();
  // Keys the invite card so the "Invite someone" chooser path can scroll to
  // it and trigger its flash highlight (both via this one GlobalKey).
  final GlobalKey<_InviteSettingsState> _inviteKey = GlobalKey();
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
    _scrollController.dispose();
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
    final l10n = context.l10n;
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
          content: Text(
            serverMessage(l10n, e.response, fallback: l10n.householdSaveFailed),
          ),
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

  /// Owner tapped the "+" in the members cloud. Rather than committing them
  /// straight to the managed-member screen, offer the choice between inviting
  /// a real member (own login) and adding a managed one (loginless).
  void _chooseAddPath() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AddSomeoneSheet(
        onInvite: _revealInvites,
        onManaged: _addManagedMember,
      ),
    );
  }

  /// "Invite someone with a login" path: make sure invites are on, then scroll
  /// to the (now code-bearing) invite card and flash it. Turning invites on
  /// patches the household in place, so the card re-renders with the code.
  Future<void> _revealInvites() async {
    if (!widget.household.invitesOpen) {
      try {
        await ref
            .read(householdActionsProvider)
            .setInvitesOpen(householdId: widget.household.id, open: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
        }
        return;
      }
    }
    if (!mounted) return;
    // Defer a frame so the code row is laid out before we scroll to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _inviteKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          alignment: 0.1,
        );
      }
      _inviteKey.currentState?.flash();
    });
  }

  /// "Add someone without a login" path: the original managed-member screen.
  void _addManagedMember() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ManagedMemberScreen(householdId: widget.household.id),
      ),
    );
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
        controller: _scrollController,
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
          BrowsePacksButton(label: context.l10n.browseMoreHomes),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: context.l10n.householdNameLabel,
                    child: TextField(
                      controller: _nameCtrl,
                      enabled: isOwner && !_busy,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: context.l10n.householdResidentsLabel,
                    child: TextField(
                      controller: _residentsCtrl,
                      enabled: isOwner && !_busy,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: context.l10n.householdResidentsHint,
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
                    label: Text(context.l10n.commonSaveChanges),
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
                              context.l10n.householdTimezone(tz),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (mismatch)
                            TextButton(
                              onPressed: _busy ? null : _setTimezoneToPhone,
                              child: Text(context.l10n.householdUsePhoneTz),
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
                    h.residents ?? context.l10n.householdMembersFallback,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _MembersList(
                    household: h,
                    viewerIsOwner: isOwner,
                    onAddMember: _chooseAddPath,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InviteSettings(key: _inviteKey, household: h),
        ],
      ),
    );
  }
}

/// The chooser shown when the owner taps "+" in the members cloud. Two clearly
/// distinguished paths: invite a real member (their own login) versus add a
/// managed member (loginless, you log chores for them).
class _AddSomeoneSheet extends StatelessWidget {
  final VoidCallback onInvite;
  final VoidCallback onManaged;
  const _AddSomeoneSheet({required this.onInvite, required this.onManaged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.addSomeoneTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _AddOptionCard(
              icon: Icons.group_add_outlined,
              title: context.l10n.addInviteTitle,
              subtitle: context.l10n.addInviteSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                onInvite();
              },
            ),
            const SizedBox(height: 12),
            _AddOptionCard(
              icon: Icons.manage_accounts_outlined,
              title: context.l10n.addManagedTitle,
              subtitle: context.l10n.addManagedSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                onManaged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable path in [_AddSomeoneSheet]: icon, title, explanatory subtitle,
/// trailing chevron.
class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteSettings extends ConsumerStatefulWidget {
  final Household household;
  const _InviteSettings({super.key, required this.household});

  @override
  ConsumerState<_InviteSettings> createState() => _InviteSettingsState();
}

class _InviteSettingsState extends ConsumerState<_InviteSettings> {
  bool _busy = false;

  /// Pulses a primary glow so the freshly-revealed code card stands out.
  /// Called via the GlobalKey from `_BodyState` once it has scrolled this
  /// card into view (shared cue with the act-as card + rewards collection).
  final _glowKey = GlobalKey<GlowHighlightState>();

  void flash() => _glowKey.currentState?.flash();

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

  /// Opens the system share sheet with a tappable join link (the app opens
  /// straight to the Join form with the code pre-filled). The literal code is
  /// kept in the text as a fallback for manual entry. The sheet's own "Copy"
  /// action covers the old copy-to-clipboard behaviour.
  Future<void> _share(String code) async {
    final l10n = context.l10n;
    await Share.share(
      l10n.inviteShareText(code),
      subject: l10n.inviteShareSubject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOwner = widget.household.isOwner;
    final isOpen = widget.household.invitesOpen;
    final code = widget.household.inviteCode;

    return GlowHighlight(
      key: _glowKey,
      child: Card(
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
                          context.l10n.inviteSomeone,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.l10n.inviteSubtitle,
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
                          isOpen
                              ? context.l10n.invitesOn
                              : context.l10n.invitesOff,
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
                      context.l10n.inviteLiveUntil,
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
                    label: Text(context.l10n.shareCode),
                    onPressed: _busy ? null : () => _share(code),
                  ),
                ),
                if (isOwner)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.generateNewCode),
                    onPressed: _busy ? null : _rotate,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersList extends ConsumerStatefulWidget {
  final Household household;
  final bool viewerIsOwner;

  /// Owner tapped the "+" chip. Opens the add-someone chooser (lives in
  /// `_BodyState` so it can coordinate with the invite card).
  final VoidCallback onAddMember;
  const _MembersList({
    required this.household,
    required this.viewerIsOwner,
    required this.onAddMember,
  });

  @override
  ConsumerState<_MembersList> createState() => _MembersListState();
}

class _MembersListState extends ConsumerState<_MembersList> {
  /// The member currently being long-press dragged, or null. While non-null
  /// the Add slot morphs into the Remove bin (same as the manage-chores
  /// cloud), labelled for the dragged member; no bin is shown otherwise.
  HouseholdMember? _draggingMember;

  // Tapping the Leave target pokes this; the draggable chip wiggles to reveal
  // it can be carried onto the target.
  final _wiggle = WiggleController();

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  /// Create (existing == null) or edit a managed (loginless) member. A pushed
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
    if (!await _confirmDeleteManaged(context, m.displayName)) return;
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
        title: Text(ctx.l10n.memberRemoveTitle(m.displayName)),
        content: Text(ctx.l10n.memberRemoveBody(m.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.memberRemove),
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
          child: Text(context.l10n.membersLoadFailed('$e')),
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
                wiggle: _wiggle,
              ),
            // Non-owners get a *persistent* Leave target (drag your own chip
            // onto it to leave) - otherwise there's no obvious way out. Owners
            // get the manage-chores behaviour: Add by default, morphing into a
            // Remove/Delete bin only while dragging a member.
            if (!widget.viewerIsOwner)
              Builder(
                builder: (binContext) => _RemoveBinChip(
                  label: context.l10n.householdLeave,
                  onDrop: (_) =>
                      _confirmAndLeave(binContext, ref, widget.household),
                  onTap: _wiggle.poke,
                ),
              )
            else if (_draggingMember != null)
              Builder(
                builder: (binContext) {
                  // Owners can't drag their own chip, so it's never a "leave".
                  final label = _draggingMember!.isManaged
                      ? context.l10n.commonDelete
                      : context.l10n.memberRemove;
                  return _RemoveBinChip(
                    label: label,
                    onDrop: (m) => m.isManaged
                        // Managed members are deleted outright, not unlinked.
                        ? _deleteManaged(binContext, ref, m)
                        : _kick(binContext, ref, m),
                  );
                },
              )
            else
              _AddMemberChip(onTap: widget.onAddMember),
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

  /// Tapped (not dropped) - pokes the chips to wiggle so it's clear you carry
  /// an avatar onto the target.
  final VoidCallback? onTap;

  const _RemoveBinChip({
    required this.onDrop,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DropTargetCircle<HouseholdMember>(
      icon: Icons.delete_outline,
      label: label,
      baseColor: Colors.red.shade300,
      hoverColor: Colors.red,
      labelWidth: 80,
      onDrop: onDrop,
      onTap: onTap,
    );
  }
}

/// A small circular corner badge (owner star, managed marker, or red remove
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

  /// Shared poke signal - a draggable chip wiggles when the Leave target is
  /// tapped, hinting that it can be carried onto the target.
  final WiggleController wiggle;

  const _MemberChip({
    required this.member,
    required this.isMe,
    required this.canDrag,
    required this.wiggle,
    this.onTap,
    this.onDragChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = ref.watch(catalogProvider).lookupAvatar(member.avatar);
    final label = isMe
        ? context.l10n.leaderboardYouSuffix(member.displayName)
        : member.displayName;

    // Corner badge: a red cross while being dragged to the bin (matches the
    // manage-chores chip), else an owner star or a managed-member marker.
    Widget? badgeFor(bool removing) {
      if (removing) return _cornerBadge(Icons.close, Colors.red, Colors.white);
      if (member.isOwner) {
        return _cornerBadge(Icons.star, scheme.primary, scheme.onPrimary);
      }
      if (member.isManaged) {
        return _cornerBadge(
          Icons.manage_accounts,
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
              context.l10n.memberOwner,
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
      result = Wiggle(
        controller: wiggle,
        child: LongPressDraggable<HouseholdMember>(
          data: member,
          onDragStarted: () => onDragChanged?.call(member),
          onDragEnd: (_) => onDragChanged?.call(null),
          // The lifted copy swaps its badge for a red cross - you're carrying
          // it toward the bin, not editing it.
          feedback: Material(
            color: Colors.transparent,
            child: chip(avatarSize: 72, removing: true),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: restingChip),
          child: restingChip,
        ),
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

/// "Add a managed member" affordance in the members cloud (owners only):
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
              painter: DashedCirclePainter(
                color: scheme.primary,
                filled: false,
              ),
              child: Icon(Icons.add, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              context.l10n.commonAdd,
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

/// Create or edit a managed (loginless) member. Mirrors the Edit Profile
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

  /// Current claim code for this managed member ("" = claiming closed). Seeded
  /// from the members view, updated locally as the owner opens/closes claiming.
  String _claimCode = '';
  bool _claimBusy = false;

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
    final l10n = context.l10n;
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
          content: Text(
            serverMessage(l10n, e.response, fallback: l10n.householdSaveFailed),
          ),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotSave('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Delete this managed member (edit mode only), with a confirm. On success
  /// pops back to the household. Mirrors the bin-drop deletion.
  Future<void> _delete() async {
    final m = widget.existing!;
    if (!await _confirmDeleteManaged(context, m.displayName) || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(householdActionsProvider)
          .deleteManagedMember(
            householdId: widget.householdId,
            userId: m.userId,
          );
      if (mounted) nav.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotDelete('$e')),
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Open (generate a code) or close (clear) claiming - mirrors the household
  /// invite toggle. The returned code is held locally for display/sharing.
  Future<void> _setClaimOpen(bool open) async {
    setState(() => _claimBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref
          .read(householdActionsProvider)
          .setClaimOpen(
            userId: widget.existing!.userId,
            householdId: widget.householdId,
            open: open,
          );
      if (mounted) setState(() => _claimCode = code ?? '');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _claimBusy = false);
    }
  }

  /// Shares a tappable claim link (opens the app to a pre-filled Sign-up in
  /// claim mode), with the literal code kept as a manual fallback.
  Future<void> _shareClaim(String code) async {
    final l10n = context.l10n;
    await Share.share(
      l10n.claimShareText(code),
      subject: l10n.claimShareSubject,
    );
  }

  /// "Give them their own login" card - the claim-code toggle, mirroring the
  /// household invite settings. Edit mode only.
  Widget _claimCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final open = _claimCode.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.claimLoginTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.l10n.claimLoginSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: open,
                  onChanged: _claimBusy ? null : _setClaimOpen,
                ),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 20),
              Text(
                _claimCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.claimCodeInfo,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(context.l10n.shareCode),
                  onPressed: _claimBusy ? null : () => _shareClaim(_claimCode),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.generateNewCode),
                onPressed: _claimBusy ? null : () => _setClaimOpen(true),
              ),
            ],
          ],
        ),
      ),
    );
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
      _claimCode = widget.existing?.claimCode ?? '';
      _nameCtrl.text = _baselineName;
      _avatar = _baselineAvatar;
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? context.l10n.editMemberTitle
              : context.l10n.addMemberTitle,
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: context.l10n.deleteMemberTooltip,
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
              BrowsePacksButton(label: context.l10n.browseMoreAvatars),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: context.l10n.displayNameLabel,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            hintText: context.l10n.memberNameHint,
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.commonRequired
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
                        label: Text(context.l10n.commonSaveChanges),
                        onPressed: (_isDirty && !_busy) ? _save : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isEdit) ...[const SizedBox(height: 16), _claimCard(context)],
            ],
          ),
        ),
      ),
    );
  }
}
