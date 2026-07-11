import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'create_household_form.dart';

/// Standalone "Create a new household" screen, reachable from the picker.
/// On success the action invalidates memberships and switches; the router
/// redirects to home, so we don't need to pop.
class CreateHouseholdScreen extends StatelessWidget {
  const CreateHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createHouseholdTitle)),
      body: const SafeArea(child: CreateHouseholdForm()),
    );
  }
}
