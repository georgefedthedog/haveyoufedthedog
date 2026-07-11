import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../widgets/labeled_field.dart';

/// "Forgot password?" - takes an email, asks PB to send a reset link,
/// then flips to a check-your-inbox confirmation. The actual password
/// change happens on the link in the email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Pre-fills the email field - passed through from whatever the user
  /// had typed on the login form.
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _busy = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(context.l10n.authResetEmailFailed('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.authResetPasswordTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.4),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _sent ? _confirmation(theme, scheme) : _form(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/general/forgotten_password.png',
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(Icons.lock_reset, size: 64, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.authResetIntro,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: context.l10n.authEmailLabel,
            child: TextFormField(
              controller: _emailCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: context.l10n.authEmailHint,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? context.l10n.authEmailHint
                  : null,
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
                : Text(context.l10n.authSendResetLink),
          ),
        ],
      ),
    );
  }

  Widget _confirmation(ThemeData theme, ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 64, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          context.l10n.authCheckInbox,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.authResetSent(_emailCtrl.text.trim()),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.authBackToLogin),
        ),
      ],
    );
  }
}
