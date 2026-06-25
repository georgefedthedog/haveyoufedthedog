import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfc_service.g.dart';

/// Writes our `/nfc-tap` universal links to NFC tags. Reading is no longer
/// done in-app at all - a tap is handled by the OS via the universal link (see
/// [NfcLaunchHandler]); this service only *writes* the tag so families don't
/// need a third-party app.
@Riverpod(keepAlive: true)
NfcService nfcService(Ref ref) => NfcService();

class NfcService {
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Writes [url] to the next tapped tag as a single NDEF URI record. Completes
  /// when the write succeeds; completes with an error message on a read-only /
  /// non-NDEF tag or a write failure. Owns the session lifecycle (one-shot). On
  /// iOS the system scan sheet appears; on Android the caller shows its own
  /// "hold a tag" UI.
  Future<void> writeUrl(String url) async {
    final completer = Completer<void>();
    try {
      await NfcManager.instance.startSession(
        // Only poll ISO-14443 (NTAG / NFC Forum Type 2 stickers) and ISO-15693.
        // The default polls FeliCa (iso18092) too, which on iOS requires the
        // `felica.systemcodes` entitlement we don't have - and starting a
        // session that needs an absent entitlement fails with "missing required
        // entitlement". We never need FeliCa, so leave it out.
        pollingOptions: const {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessage: 'Hold a tag near the top of your phone.',
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          String? error;
          if (ndef == null) {
            error = "This tag can't store a link (not NDEF).";
          } else if (!ndef.isWritable) {
            error = 'This tag is read-only.';
          }
          if (error != null) {
            await NfcManager.instance.stopSession(errorMessage: error);
            if (!completer.isCompleted) completer.completeError(error);
            return;
          }
          try {
            await ndef!.write(
              NdefMessage([NdefRecord.createUri(Uri.parse(url))]),
            );
            await NfcManager.instance.stopSession(alertMessage: 'Tag written!');
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessage: "Couldn't write to the tag.",
            );
            if (!completer.isCompleted) {
              completer.completeError("Couldn't write to the tag.");
            }
          }
        },
        onError: (NfcError error) async {
          if (!completer.isCompleted) completer.completeError(error.message);
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.completeError('$e');
    }
    return completer.future;
  }
}
