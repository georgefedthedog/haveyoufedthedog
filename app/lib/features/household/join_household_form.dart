import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/household/household_actions.dart';
import '../../widgets/labeled_field.dart';

/// Invite code input + Join button. On success the router redirects.
class JoinHouseholdForm extends ConsumerStatefulWidget {
  const JoinHouseholdForm({super.key, this.initialCode});

  /// Pre-filled invite code from a shared join deep link, if any.
  final String? initialCode;

  @override
  ConsumerState<JoinHouseholdForm> createState() =>
      _JoinHouseholdFormState();
}

class _JoinHouseholdFormState extends ConsumerState<JoinHouseholdForm> {
  final _formKey = GlobalKey<FormState>();
  late final _codeCtrl = TextEditingController(
    text: widget.initialCode?.trim() ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(householdActionsProvider)
          .joinByCode(_codeCtrl.text.trim());
    } on ClientException catch (e) {
      final msg = e.response['message'] as String? ?? 'Could not join';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(showCloseIcon: true, content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(showCloseIcon: true, content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Text(
            'Got a code from a family member? Paste it here to join '
            'their household.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Invite code',
            child: TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. KIKO-7H4P',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join household'),
          ),
        ],
      ),
    );
  }
}
