import 'package:flutter/material.dart';

import 'join_household_form.dart';

/// Standalone "Join by invite code" screen, reachable from the picker.
class JoinHouseholdScreen extends StatelessWidget {
  const JoinHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join household')),
      body: const SafeArea(child: JoinHouseholdForm()),
    );
  }
}
