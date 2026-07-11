import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/api/server_messages.dart';
import '../../core/household/household_actions.dart';
import '../../l10n/l10n.dart';
import '../../widgets/labeled_field.dart';

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
  final _residentsCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _residentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(householdActionsProvider)
          .createHousehold(
            _nameCtrl.text.trim(),
            residents: _residentsCtrl.text.trim(),
          );
      // Router redirects when memberships update.
    } on ClientException catch (e) {
      if (mounted) {
        final msg = serverMessage(
          context.l10n,
          e.response,
          fallback: context.l10n.createHouseholdFailed,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text('$e')));
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
            context.l10n.createHouseholdIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Same card layout as the household details screen.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: context.l10n.householdNameLabel,
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: context.l10n.householdNameHint,
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.l10n.commonRequired
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Optional, same field as on household details - empty
                  // is fine.
                  LabeledField(
                    label: context.l10n.householdResidentsLabel,
                    child: TextFormField(
                      controller: _residentsCtrl,
                      decoration: InputDecoration(
                        hintText: context.l10n.householdResidentsHint,
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.createHouseholdTitle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
