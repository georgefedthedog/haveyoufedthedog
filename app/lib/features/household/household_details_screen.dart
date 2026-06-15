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
import '../../widgets/labeled_field.dart';
import '../profile/avatar_artwork.dart';
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
        // Generous bottom inset so the packs accordion (last card) has
        // somewhere to expand into - otherwise it opens flush against
        // the screen edge and you can't tell anything happened.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
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
          const BrowsePacksButton(),
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
          const SizedBox(height: 24),
          _PackSettings(household: h),
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

/// Redeem an image-pack code for this household, and list the packs it
/// already has. Any member can redeem - codes are gifts, not licences.
///
/// Collapsed to its header row by default - tap to expand (this is the
/// rarest-used card on the screen).
/// Type the code, then long-press the gift chip (the code shows beneath
/// it) and carry it into the dashed Apply circle - same drag mechanic as
/// the account card's switch/log-out. The deliberate gesture *is* the
/// confirmation. The new art appears in the pickers as soon as the
/// catalog refetches (triggered automatically by the in-place pack
/// update).
class _PackSettings extends ConsumerStatefulWidget {
  final Household household;
  const _PackSettings({required this.household});

  @override
  ConsumerState<_PackSettings> createState() => _PackSettingsState();
}

class _PackSettingsState extends ConsumerState<_PackSettings> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  bool _expanded = false;

  /// Matches the server-side minimum code length (catalog_packs.code
  /// min 4) - below this the gift chip is visibly parked and won't drag.
  bool get _codeReady => _codeCtrl.text.trim().length >= 4;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(householdActionsProvider)
          .redeemPackCode(
            householdId: widget.household.id,
            rawCode: _codeCtrl.text,
          );
      // Unfocus before clearing: with the field still focused, Android's
      // IME can reassert its composing text over a programmatic clear.
      FocusManager.instance.primaryFocus?.unfocus();
      _codeCtrl.clear();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            result.alreadyApplied
                ? '${result.name} is already applied.'
                : '${result.name} applied!',
          ),
        ),
      );
    } on ClientException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            e.response['message'] as String? ?? 'Could not apply that code',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The thing you drag: a gift badge with the typed code beneath it.
  /// Same chip sizing as the account card (56 resting, 72 in flight).
  /// Greyed and inert until the code reaches 4 characters; while busy it
  /// hosts the spinner instead - no scrim, per the house busy-state rule.
  Widget _giftChipDraggable(ThemeData theme) {
    final scheme = theme.colorScheme;
    final code = _codeCtrl.text.trim().toUpperCase();
    final active = _codeReady && !_busy;

    Widget chip({required double size}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _codeReady
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
            ),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.card_giftcard,
                    size: size * 0.45,
                    color: _codeReady
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 110,
            child: Text(
              code,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: _codeReady ? null : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final resting = chip(size: 56);
    if (!active) return resting;
    return LongPressDraggable<String>(
      data: code,
      feedback: Material(color: Colors.transparent, child: chip(size: 72)),
      childWhenDragging: Opacity(opacity: 0.3, child: resting),
      child: resting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Names resolve through the catalog; ids whose pack is unknown
    // (disabled / deleted / catalog not loaded yet) are silently skipped.
    final catalog = ref.watch(catalogProvider);
    final appliedNames = [
      for (final id in widget.household.packIds) ?catalog.packName(id),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accordion header - whole row toggles.
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image packs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Unlock extra art with a pack code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Applied packs stay visible even when collapsed - the pills
            // are the at-a-glance proof of what this household has.
            if (appliedNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in appliedNames)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Pack code',
                          child: TextField(
                            controller: _codeCtrl,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'WOOF-2026',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _giftChipDraggable(theme),
                              _ApplyDropCircle(
                                enabled: !_busy,
                                onDrop: _apply,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed Apply circle the gift chip gets carried into. Fills solid
/// primary while a drag hovers, mirroring the account card's circles.
/// Applying a pack is additive and reversible-by-admin, so no confirm
/// dialog - the deliberate drag is the confirmation.
class _ApplyDropCircle extends StatelessWidget {
  final bool enabled;
  final VoidCallback onDrop;

  const _ApplyDropCircle({required this.enabled, required this.onDrop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (_) => onDrop(),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: DashedCirclePainter(color: color, filled: hovering),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.redeem,
                  size: 24,
                  color: hovering ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: Text(
                'Apply pack',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
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
      await ref
          .read(householdActionsProvider)
          .kickMember(membershipId: m.membershipId, householdId: household.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMembers = ref.watch(
      householdMembersControllerProvider(household.id),
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
        // household.
        final otherCount = members.where((m) => m.userId != myUserId).length;
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
              Builder(
                builder: (binContext) {
                  return _RemoveBinChip(
                    label: viewerIsOwner ? 'Remove' : 'Leave',
                    onDrop: (m) => m.userId == myUserId
                        ? _confirmAndLeave(binContext, ref, household)
                        : _kick(binContext, ref, m),
                  );
                },
              ),
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
class _MemberChip extends ConsumerWidget {
  final HouseholdMember member;
  final bool isMe;
  final bool canDrag;

  const _MemberChip({
    required this.member,
    required this.isMe,
    required this.canDrag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = ref.watch(catalogProvider).lookupAvatar(member.avatar);
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
                child: Icon(Icons.star, size: 12, color: scheme.onPrimary),
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

    // Long-press to lift - a plain Draggable claims the gesture arena
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
