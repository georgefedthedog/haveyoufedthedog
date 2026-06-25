import 'package:flutter/foundation.dart';

/// TEMPORARY shared on-device debug log. Backs the "Debug log" card on the Edit
/// Profile screen so we can see `debugPrint` output on a TestFlight phone with
/// no console attached. Remove with the card once no longer needed.
///
/// Capped to the most recent [_maxLines] entries so a long session can't grow
/// the buffer (or the rendered list) without bound.
final debugLog = ValueNotifier<List<String>>(const []);

const _maxLines = 300;
final _startedAt = DateTime.now();

/// Appends one timestamped line, trimming the oldest entries past the cap.
void logDebug(String message) {
  final secs = DateTime.now().difference(_startedAt).inMilliseconds / 1000;
  final next = [...debugLog.value, '[+${secs.toStringAsFixed(1)}s] $message'];
  if (next.length > _maxLines) {
    next.removeRange(0, next.length - _maxLines);
  }
  debugLog.value = next;
}

/// Routes every `debugPrint(...)` in the app into [debugLog] as well as the
/// real console sink. Call once, early in `main()`. (`debugPrint` runs in
/// release builds too, so this works on TestFlight.)
void installDebugLogCapture() {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) logDebug(message);
    original(message, wrapWidth: wrapWidth);
  };
}
