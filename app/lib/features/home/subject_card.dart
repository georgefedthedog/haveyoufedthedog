import 'package:flutter/material.dart';

import '../../core/subjects/subject.dart';

/// One row in the subjects list on the home screen. For Step 6 this is
/// purely presentational — Step 7 adds chore-status chips, Step 8 makes
/// them tappable.
class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _Avatar(icon: subject.icon),
        title: Text(subject.name),
        subtitle: subject.nfcTagId != null
            ? const Text('NFC tag registered')
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? icon;
  const _Avatar({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: Text(
        (icon != null && icon!.isNotEmpty) ? icon! : '🐾',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
