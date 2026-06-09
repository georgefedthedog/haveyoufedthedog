import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/household/household.dart';
import '../../core/household/household_actions.dart';
import '../../core/household/households_controller.dart';
import '../../widgets/build_label.dart';

/// Dedicated invite screen — the "Bring the crew together!" surface from
/// the mockups. Hero illustration placeholder + big invite code + share.
class InviteScreen extends ConsumerWidget {
  final String householdId;

  const InviteScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHouseholds = ref.watch(householdsControllerProvider);

    return asyncHouseholds.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (households) {
        Household? h;
        for (final candidate in households) {
          if (candidate.id == householdId) {
            h = candidate;
            break;
          }
        }
        if (h == null) {
          return Scaffold(
            appBar: AppBar(),
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
        return _InviteBody(household: h);
      },
    );
  }
}

class _InviteBody extends ConsumerStatefulWidget {
  final Household household;
  const _InviteBody({required this.household});

  @override
  ConsumerState<_InviteBody> createState() => _InviteBodyState();
}

class _InviteBodyState extends ConsumerState<_InviteBody> {
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
        content: Text('Copied $code'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.household;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOwner = h.isOwner;
    final isOpen = h.invitesOpen;
    final code = h.inviteCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Invite someone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero illustration placeholder — the people-high-fiving
              // shot from the mockup lives here once real art ships.
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text('🙌',
                      style: TextStyle(
                          fontSize: 96,
                          color: scheme.onPrimaryContainer)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bring the crew together!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share this code with a household member so they can join.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (!isOpen) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Invites are off.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOwner
                              ? 'Turn them on to mint a fresh invite code.'
                              : 'Only an owner can turn invites on.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Open invites'),
                            onPressed: _busy ? null : () => _toggle(true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (code != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        children: [
                          Text(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14,
                                  color: scheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                'Live until you turn invites off',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share code'),
                            onPressed:
                                _busy ? null : () => _copy(code),
                          ),
                          if (isOwner) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate new code'),
                              onPressed: _busy ? null : _rotate,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Invites are on, but no code is set. '
                        '${isOwner ? "Tap the refresh button to mint one." : "Wait for an owner to mint a code."}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                if (isOwner) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Close invites'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    onPressed: _busy ? null : () => _toggle(false),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
