import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/password_field.dart';

/// Display name + email + password + submit. On success, PB signs the new
/// user in immediately; the router redirect handles the navigation.
class SignupForm extends ConsumerStatefulWidget {
  const SignupForm({super.key, this.initialClaimCode});

  /// Claim code carried in from a `…/claim?code=` deep link. When present the
  /// form opens with the claim section expanded and the code filled, switching
  /// it into "take over a managed member" mode.
  final String? initialClaimCode;

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _claimCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  bool _busy = false;
  bool _claimExpanded = false;

  /// True when the claim code was pre-filled from a deep link. Drives focus
  /// to the Name box (the code's already there, so the name is what's next)
  /// and suppresses the claim field's own autofocus.
  bool _claimFromLink = false;

  /// A non-empty claim code switches this form from "create a new account" to
  /// "take over an existing managed member".
  bool get _isClaim => _claimCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final code = widget.initialClaimCode?.trim() ?? '';
    if (code.isNotEmpty) {
      // Pre-fill from the deep link before the first build - no setState.
      _claimCtrl.text = code;
      _claimExpanded = true;
      _claimFromLink = true;
      _focusNameSoon();
    }
  }

  @override
  void didUpdateWidget(SignupForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A claim link can arrive while this form is already mounted (the user was
    // on the Sign-up tab). initState won't re-run, so apply it here.
    final code = widget.initialClaimCode?.trim() ?? '';
    if (code.isNotEmpty && code != (oldWidget.initialClaimCode?.trim() ?? '')) {
      setState(() {
        _claimCtrl.text = code;
        _claimExpanded = true;
        _claimFromLink = true;
      });
      _focusNameSoon();
    }
  }

  /// Move focus to the Name box once the pre-filled fields have laid out.
  void _focusNameSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _claimCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final claim = _isClaim;
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (claim) {
        // A claim code commits to claiming: an invalid/used code fails here
        // (the endpoint 404s) rather than quietly creating a new account.
        await auth.claimAccount(
          code: _claimCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
      } else {
        await auth.signup(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
      }
      // Close the autofill flow so the platform can offer to save the
      // credential.
      TextInput.finishAutofillContext();
    } on ClientException catch (e) {
      if (mounted) {
        final fallback = claim
            ? context.l10n.authCouldNotClaim
            : context.l10n.authSignupFailed;
        final msg = e.response['message'] as String? ?? fallback;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(context.l10n.authSignupFailedDetails('$e')),
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
              label: context.l10n.authYourNameLabel,
              child: TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                decoration: InputDecoration(
                  hintText: _isClaim
                      ? context.l10n.authNameHintClaim
                      : context.l10n.authNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                // Claiming keeps the owner-set name, so it's optional then.
                validator: (v) => (!_isClaim && (v == null || v.trim().isEmpty))
                    ? context.l10n.commonRequired
                    : null,
              ),
            ),
            const SizedBox(height: 16),
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
                    ? context.l10n.authEmailInvalid
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordCtrl,
              helperText: context.l10n.authPasswordRule,
              hintText: context.l10n.authChoosePasswordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.length < 8)
                  ? context.l10n.authPasswordRule
                  : null,
            ),
            const SizedBox(height: 8),
            // Tucked behind a disclosure: normal signups never see the field.
            // Collapsing clears the code so the form can't be silently in
            // "claim" mode with the field hidden.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _claimExpanded = !_claimExpanded;
                        if (!_claimExpanded) _claimCtrl.clear();
                      }),
                icon: Icon(
                  _claimExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(context.l10n.authClaimCodeToggle),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _claimExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LabeledField(
                        label: context.l10n.authClaimCodeLabel,
                        child: TextFormField(
                          controller: _claimCtrl,
                          // Manual "I have a claim code" expansion focuses here
                          // to type; a deep-link pre-fill focuses Name instead.
                          autofocus: !_claimFromLink,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: context.l10n.authClaimCodeHint,
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                          ),
                          // Drives the name validator + the button label.
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
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
                  : Text(
                      _isClaim
                          ? context.l10n.authClaimAccount
                          : context.l10n.authSignUp,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
