import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/api/server_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../router/routes.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/password_field.dart';

/// The email + password fields, the submit button, and the in-progress state.
/// No layout chrome - the screen wraps it in a Scaffold.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      // Tell the platform the autofill flow is done so it can offer to save
      // the credential the user just signed in with.
      TextInput.finishAutofillContext();
      // Router will redirect to /home automatically because auth state changed.
    } on ClientException catch (e) {
      if (mounted) {
        final msg = serverMessage(
          context.l10n,
          e.response,
          fallback: context.l10n.authLoginFailed,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(context.l10n.authLoginFailedDetails('$e')),
          ),
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
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: context.l10n.authEmailLabel,
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: context.l10n.authEmailHint,
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? context.l10n.authEmailHint
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordCtrl,
              hintText: context.l10n.authPasswordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.isEmpty)
                  ? context.l10n.authPasswordHint
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(
                  Routes.forgotPassword,
                  extra: _emailCtrl.text.trim(),
                ),
                child: Text(context.l10n.authForgotPassword),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.authLogIn),
            ),
          ],
        ),
      ),
    );
  }
}
