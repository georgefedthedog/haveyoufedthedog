import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nfc/nfc_service.dart';
import '../../l10n/l10n.dart';

/// Writes [url] to a tag. Pops `true` on success. On iOS the system scan sheet
/// drives the interaction; on Android this dialog is the "hold a tag" prompt.
class NfcWriteDialog extends ConsumerStatefulWidget {
  final String url;
  const NfcWriteDialog({super.key, required this.url});

  @override
  ConsumerState<NfcWriteDialog> createState() => _NfcWriteDialogState();
}

class _NfcWriteDialogState extends ConsumerState<NfcWriteDialog> {
  String? _error;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _unavailable = false;
    });
    final svc = ref.read(nfcServiceProvider);
    if (!await svc.isAvailable()) {
      if (mounted) setState(() => _unavailable = true);
      return;
    }
    try {
      await svc.writeUrl(widget.url);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget body;
    if (_unavailable) {
      body = Text(
        context.l10n.nfcUnavailable,
        style: theme.textTheme.bodyMedium,
      );
    } else if (_error != null) {
      body = Text(_error!, style: theme.textTheme.bodyMedium);
    } else {
      body = Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.l10n.nfcHoldTag,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(context.l10n.nfcWriteTagTitle),
      content: body,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        if (_error != null || _unavailable)
          FilledButton(
            onPressed: _start,
            child: Text(context.l10n.commonTryAgain),
          ),
      ],
    );
  }
}
