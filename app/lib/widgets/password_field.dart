import 'package:flutter/material.dart';

import 'labeled_field.dart';

/// A `TextFormField` for passwords with a built-in eye toggle. Use this in
/// place of a raw `TextFormField` anywhere we ask for a password.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String? hintText;
  final Widget? prefixIcon;
  final List<String> autofillHints;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.helperText,
    this.hintText,
    this.prefixIcon,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: widget.labelText,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscured,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        decoration: InputDecoration(
          helperText: widget.helperText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: IconButton(
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            tooltip: _obscured ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
      ),
    );
  }
}
