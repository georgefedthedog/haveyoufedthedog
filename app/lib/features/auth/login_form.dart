import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/auth/auth_controller.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/password_field.dart';

/// The email + password fields, the submit button, and the in-progress state.
/// No layout chrome — the screen wraps it in a Scaffold.
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
      await ref.read(authControllerProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      // Router will redirect to /home automatically because auth state changed.
    } on ClientException catch (e) {
      final msg = e.response['message'] as String? ?? 'Login failed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(showCloseIcon: true, content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(showCloseIcon: true, content: Text('Login failed: $e')),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Email',
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter your email' : null,
            ),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordCtrl,
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
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
                : const Text('Log in'),
          ),
        ],
      ),
    );
  }
}
