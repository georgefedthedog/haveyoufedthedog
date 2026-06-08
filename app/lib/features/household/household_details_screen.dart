import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/household_member.dart';
import '../../core/household/household_members_controller.dart';
import '../../core/household/households_controller.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';

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
            bottomNavigationBar: const SafeArea(child: BuildLabel()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(household.name),
            actions: [
              IconButton(
                icon: Icon(household.isOwner
                    ? Icons.delete_outline
                    : Icons.logout),
                tooltip: household.isOwner
                    ? 'Delete household'
                    : 'Leave household',
                onPressed: () => household.isOwner
                    ? _confirmAndDelete(context, ref, household)
                    : _confirmAndLeave(context, ref, household),
              ),
            ],
          ),
          body: _Body(household: household),
          bottomNavigationBar: const SafeArea(child: BuildLabel()),
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

class _Body extends ConsumerWidget {
  final Household household;
  const _Body({required this.household});

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: household.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename household'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null ||
        newName.isEmpty ||
        newName == household.name) {
      return;
    }
    try {
      await ref.read(householdActionsProvider).renameHousehold(
            householdId: household.id,
            newName: newName,
          );
    } on ClientException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text(e.response['message'] as String? ?? 'Rename failed'),
        ));
      }
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
    final isOwner = household.isOwner;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(household.name),
            subtitle: Text('Your role: ${household.role}'),
            trailing: isOwner
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Rename',
                    onPressed: () => _rename(context, ref),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        _InviteSettings(household: household),
        const SizedBox(height: 24),
        Text('Members', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _MembersList(
          householdId: household.id,
          viewerIsOwner: isOwner,
        ),
      ],
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

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Copied $code'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.household.isOwner;
    final isOpen = widget.household.invitesOpen;
    final code = widget.household.inviteCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open to new members',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        isOwner
                            ? 'Turning this on generates a fresh invite code.'
                            : 'Only an owner can change this.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (isOwner && !_busy) ? _toggle : null,
                ),
              ],
            ),
            if (isOpen && code != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 22,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Copy',
                      onPressed: _busy ? null : () => _copy(code),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Rotate code',
                        onPressed: _busy ? null : _rotate,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  final String householdId;
  final bool viewerIsOwner;
  const _MembersList({required this.householdId, required this.viewerIsOwner});

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
            householdId: householdId,
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
        ref.watch(householdMembersControllerProvider(householdId));
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
      data: (members) => Column(
        children: [
          for (final m in members)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(m.userId == myUserId
                    ? '${m.displayName} (you)'
                    : m.displayName),
                subtitle: Text(m.role),
                trailing: (viewerIsOwner && m.userId != myUserId)
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        tooltip: 'Remove from household',
                        onPressed: () => _kick(context, ref, m),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
