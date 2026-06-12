import 'package:flutter/material.dart';

/// Renders [label] above [child] in the theme's primary colour - the
/// app-wide convention for text inputs (label sits outside the filled
/// rounded box, matching the focus-border colour).
///
/// Use with a labelText-free `TextField`/`TextFormField` as the child:
///
/// ```dart
/// LabeledField(
///   label: 'Household name',
///   child: TextField(controller: _ctrl),
/// )
/// ```
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
