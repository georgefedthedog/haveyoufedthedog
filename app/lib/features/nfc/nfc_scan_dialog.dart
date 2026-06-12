import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nfc/nfc_service.dart';

/// Modal that captures the next NFC tag scan and returns its id. Uses
/// [NfcService.pushHandler] so the home-screen listener stays installed
/// underneath - when the dialog closes the previous handler is restored.
///
/// Returns the scanned tag id, or null if the user dismissed.
class NfcScanDialog extends ConsumerStatefulWidget {
  const NfcScanDialog({super.key});

  @override
  ConsumerState<NfcScanDialog> createState() => _NfcScanDialogState();
}

class _NfcScanDialogState extends ConsumerState<NfcScanDialog> {
  NfcHandlerToken? _token;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_start);
  }

  Future<void> _start() async {
    final svc = ref.read(nfcServiceProvider);
    final available = await svc.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _error = "This device doesn't have NFC available.");
      return;
    }
    // Push our handler on top of whatever's installed (the long-lived
    // launch handler in most cases). pushHandler stores it as `_previous`
    // so restore() puts the launch handler back when this dialog closes.
    await svc.ensureStarted();
    if (!mounted) return;
    _token = svc.pushHandler((tagId) {
      if (!mounted) return;
      Navigator.of(context).pop(tagId);
    });
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _token?.restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan NFC tag'),
      content: SizedBox(
        height: 120,
        child: Center(
          child: _error != null
              ? Text(_error!, textAlign: TextAlign.center)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _ready ? Icons.nfc : Icons.hourglass_top,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ready
                          ? 'Hold the tag near the back of your phone.'
                          : 'Starting NFC…',
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
