import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/household/nfc_setting_highlight_controller.dart';
import '../../core/storage/nfc_tap_action_controller.dart';
import '../../l10n/l10n.dart';
import '../../widgets/glow_highlight.dart';

/// The per-device NFC tap-behaviour toggle (tap completes the chore vs opens
/// the subject's page), shown on the You tab. Saves instantly via
/// [nfcTapActionControllerProvider]. Also the landing point for the one-shot
/// cue from a subject's NFC-tag card ([nfcSettingHighlightProvider]): scrolls
/// itself into view and pulses, mirroring the act-as card's Home→You cue.
class NfcSettingCard extends ConsumerStatefulWidget {
  const NfcSettingCard({super.key});

  @override
  ConsumerState<NfcSettingCard> createState() => _NfcSettingCardState();
}

class _NfcSettingCardState extends ConsumerState<NfcSettingCard> {
  final _glowKey = GlobalKey<GlowHighlightState>();

  /// Guards against re-handling the same highlight request across rebuilds.
  bool _handled = false;

  /// Scroll this card into view and pulse its border. Triggered once when a
  /// pending highlight request lands (after navigating here from a subject's
  /// NFC-tag card).
  void _handleHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(nfcSettingHighlightProvider.notifier).consume();
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        alignment: 0.2,
      );
      _glowKey.currentState?.flash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completesChore =
        ref.watch(nfcTapActionControllerProvider).valueOrNull ?? true;

    // Only act on a pending highlight once per request; consuming the flag
    // flips it false, which resets the guard for the next tap.
    final wantHighlight = ref.watch(nfcSettingHighlightProvider);
    if (wantHighlight && !_handled) {
      _handled = true;
      _handleHighlight();
    } else if (!wantHighlight) {
      _handled = false;
    }

    return GlowHighlight(
      key: _glowKey,
      borderRadius: 20,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Mirrors the invite card's header row on household details: icon,
          // titleSmall + bodySmall copy, switch.
          child: Row(
            children: [
              const Icon(Icons.nfc),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.nfcCompleteOnTap,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      completesChore
                          ? context.l10n.nfcTapCompletesDesc
                          : context.l10n.nfcTapOpensDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: completesChore,
                // Saves immediately - a device preference.
                onChanged: (v) => ref
                    .read(nfcTapActionControllerProvider.notifier)
                    .setCompletesChore(v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
