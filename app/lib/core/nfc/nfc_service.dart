import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfc_service.g.dart';

typedef NfcTagHandler = void Function(String tagId);

/// Returned by [NfcService.pushHandler]. Restoring puts the previous handler
/// back in place. Lets a scan dialog (or any modal) take over the next tap
/// without tearing down the home-screen listener.
class NfcHandlerToken {
  final NfcService _svc;
  final NfcTagHandler? _previous;
  bool _disposed = false;
  NfcHandlerToken._(this._svc, this._previous);

  void restore() {
    if (_disposed) return;
    _disposed = true;
    _svc._handler = _previous;
  }
}

/// Long-lived NFC session wrapper.
///
/// One reader session is started lazily on the first [setHandler] call and
/// reused for the app's lifetime. Handlers can be pushed/restored to support
/// modal scan flows without dropping the home-screen listener.
@Riverpod(keepAlive: true)
NfcService nfcService(Ref ref) {
  final svc = NfcService();
  ref.onDispose(svc.stop);
  return svc;
}

class NfcService {
  bool _started = false;
  NfcTagHandler? _handler;

  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Sets the active tag handler. Doesn't touch the underlying session —
  /// use [ensureStarted] for that. Kept separate so a scan-dialog can
  /// safely [ensureStarted] without clobbering the long-lived default
  /// handler before [pushHandler] saves it as `_previous`.
  void setHandler(NfcTagHandler onTag) {
    _handler = onTag;
  }

  /// Starts the underlying nfc_manager session if not already running.
  /// Idempotent — safe to call multiple times.
  Future<void> ensureStarted({
    void Function(Object error)? onError,
  }) async {
    if (_started) return;
    _started = true;
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final id = _extractUid(tag);
          if (id != null) _handler?.call(id);
        },
        onError: (NfcError err) async {
          _started = false;
          onError?.call(err);
        },
      );
    } catch (e) {
      _started = false;
      onError?.call(e);
    }
  }

  /// Temporarily replace the handler — call `.restore()` on the returned
  /// token to put the previous handler back. The NFC session itself keeps
  /// running, so any background listener (e.g. the home screen's) is
  /// preserved across modals.
  NfcHandlerToken pushHandler(NfcTagHandler onTag) {
    final token = NfcHandlerToken._(this, _handler);
    _handler = onTag;
    return token;
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _handler = null;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  // Tags identify themselves through one of several tech maps. Walk them
  // in priority order and pull the first identifier we find.
  static String? _extractUid(NfcTag tag) {
    final data = tag.data;
    const keysToCheck = [
      'nfca',
      'nfcb',
      'nfcf',
      'nfcv',
      'mifareclassic',
      'mifareultralight',
      'isodep',
      'mifare',
      'iso15693',
      'iso7816',
    ];
    for (final key in keysToCheck) {
      final tech = data[key];
      if (tech is Map && tech['identifier'] != null) {
        return _bytesToHex(tech['identifier']);
      }
    }
    return null;
  }

  static String _bytesToHex(dynamic bytes) {
    if (bytes is List<int>) {
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }
    if (bytes is Uint8List) {
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    }
    return bytes.toString();
  }
}
