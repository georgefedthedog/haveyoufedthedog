import 'package:flutter/material.dart';

/// A grave-action confirmation: the destructive button stays disabled until
/// the user types [confirmWord] (default "DELETE"). For irreversible actions
/// like deleting your account or a managed member. Returns true only if
/// confirmed.
Future<bool> confirmByTyping(
  BuildContext context, {
  required String title,
  required String body,
  String confirmWord = 'DELETE',
  String actionLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmByTypingDialog(
      title: title,
      body: body,
      confirmWord: confirmWord,
      actionLabel: actionLabel,
    ),
  );
  return result ?? false;
}

/// Stateful so the controller's dispose follows the dialog lifecycle - the
/// dialog rebuilds during its exit animation, after showDialog's future has
/// already resolved, so disposing at the call site blows up.
class _ConfirmByTypingDialog extends StatefulWidget {
  final String title;
  final String body;
  final String confirmWord;
  final String actionLabel;

  const _ConfirmByTypingDialog({
    required this.title,
    required this.body,
    required this.confirmWord,
    required this.actionLabel,
  });

  @override
  State<_ConfirmByTypingDialog> createState() => _ConfirmByTypingDialogState();
}

class _ConfirmByTypingDialogState extends State<_ConfirmByTypingDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok =
        _typed.text.trim().toUpperCase() == widget.confirmWord.toUpperCase();
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.body),
          const SizedBox(height: 16),
          TextField(
            controller: _typed,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Type ${widget.confirmWord} to confirm',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: ok ? () => Navigator.pop(context, true) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
