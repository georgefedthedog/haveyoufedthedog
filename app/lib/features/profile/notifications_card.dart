import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';

/// The three per-user push toggles (reminders / chores logged / award wins),
/// shown on the You tab. Stored muted-polarity on the user record (`mute_*` -
/// so the missing-field default means "on"), shown positive. Saves immediately
/// on toggle; the PB SDK syncs the auth record on save, so watchers repaint.
/// A per-flag optimistic override keeps the thumb moving while the write is in
/// flight (server round-trip, unlike the instant local NFC / language cards).
class NotificationsCard extends ConsumerStatefulWidget {
  const NotificationsCard({super.key});

  @override
  ConsumerState<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<NotificationsCard> {
  /// Optimistic mute values while a save is in flight, keyed by PB field.
  final _pending = <String, bool>{};

  Future<void> _set(String field, bool mute) async {
    setState(() => _pending[field] = mute);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateNotificationPrefs(
            muteOverdue: field == 'mute_overdue' ? mute : null,
            muteCompletions: field == 'mute_completions' ? mute : null,
            muteAwards: field == 'mute_awards' ? mute : null,
          );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(l10n.commonCouldNotSave('$e')),
        ),
      );
    } finally {
      // On success auth already carries the new value; on error the thumb
      // springs back to the stored one.
      if (mounted) setState(() => _pending.remove(field));
    }
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String description,
    required String field,
    required bool muted,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Mirrors the NFC card's row: icon, titleSmall + bodySmall copy, switch.
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
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
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: !(_pending[field] ?? muted),
          onChanged: (v) => _set(field, !v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    if (auth == null || !auth.isAuthenticated) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(
              icon: Icons.notifications_active_outlined,
              title: context.l10n.profileNotifyReminders,
              description: context.l10n.profileNotifyRemindersDesc,
              field: 'mute_overdue',
              muted: auth.muteOverdue,
            ),
            const SizedBox(height: 12),
            _row(
              icon: Icons.check_circle_outline,
              title: context.l10n.profileNotifyCompletions,
              description: context.l10n.profileNotifyCompletionsDesc,
              field: 'mute_completions',
              muted: auth.muteCompletions,
            ),
            const SizedBox(height: 12),
            _row(
              icon: Icons.emoji_events_outlined,
              title: context.l10n.profileNotifyAwards,
              description: context.l10n.profileNotifyAwardsDesc,
              field: 'mute_awards',
              muted: auth.muteAwards,
            ),
          ],
        ),
      ),
    );
  }
}
