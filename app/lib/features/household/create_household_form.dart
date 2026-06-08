import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/household/household_actions.dart';

/// Name input + Create button. On success the router redirects to /home.
class CreateHouseholdForm extends ConsumerStatefulWidget {
  const CreateHouseholdForm({super.key});

  @override
  ConsumerState<CreateHouseholdForm> createState() =>
      _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends ConsumerState<CreateHouseholdForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(householdActionsProvider)
          .createHousehold(_nameCtrl.text.trim());
      // Router redirects when memberships update.
    } on ClientException catch (e) {
      final msg = e.response['message'] as String? ?? 'Could not create';
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
            'Start a new household — for your family, flatmates, '
            'or anyone you share chores with.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Household name',
              hintText: 'e.g. "Paihia House" or "Home"',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                : const Text('Create household'),
          ),
        ],
      ),
    );
  }
}
