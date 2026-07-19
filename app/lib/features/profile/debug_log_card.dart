import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/diagnostics/debug_log.dart';

/// TEMPORARY: the live on-device debug log (all `debugPrint` output, captured
/// via [installDebugLogCapture]) so we can read logs on a console-less
/// TestFlight build. Hidden behind a "Here be dragons" link so it's out of the
/// way for normal use; tap to reveal. Newest line first, fixed-height scroll,
/// capped buffer. Copy shares the whole log; Clear empties it for a fresh
/// repro. Remove once no longer needed.
class DebugLogCard extends StatefulWidget {
  const DebugLogCard({super.key});

  @override
  State<DebugLogCard> createState() => _DebugLogCardState();
}

class _DebugLogCardState extends State<DebugLogCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_revealed) {
      return Center(
        child: TextButton(
          onPressed: () => setState(() => _revealed = true),
          child: Text(
            '🐉  Here there be dragons  🐉',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: debugLog,
          builder: (context, lines, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Debug log (${lines.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: lines.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: lines.join('\n')),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied')),
                              );
                            },
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: lines.isEmpty
                          ? null
                          : () => debugLog.value = const [],
                    ),
                    IconButton(
                      tooltip: 'Hide',
                      icon: const Icon(Icons.expand_less, size: 18),
                      onPressed: () => setState(() => _revealed = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (lines.isEmpty)
                  Text('No debug output yet.', style: theme.textTheme.bodySmall)
                else
                  SizedBox(
                    height: 260,
                    child: Scrollbar(
                      child: ListView.builder(
                        primary: false,
                        itemCount: lines.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          // Newest first.
                          child: Text(
                            lines[lines.length - 1 - i],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
