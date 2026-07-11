import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'join_household_form.dart';

/// Standalone "Join by invite code" screen, reachable from the picker or from
/// a shared join deep link (which pre-fills [initialCode]).
class JoinHouseholdScreen extends StatelessWidget {
  const JoinHouseholdScreen({super.key, this.initialCode});

  /// Invite code carried in from a `…/join?code=` deep link, pre-filled into
  /// the form. Null when reached the normal way (from the picker).
  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.joinHouseholdTitle)),
      body: SafeArea(child: JoinHouseholdForm(initialCode: initialCode)),
    );
  }
}
