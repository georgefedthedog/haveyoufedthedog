import 'package:flutter/material.dart';

import '../../widgets/build_label.dart';
import 'login_form.dart';

/// Container for the login flow. Form lives in its own file so it can be
/// swapped into the signup tab container in Step 3 without copy-paste.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Have You Fed The Dog?')),
      body: const SafeArea(child: LoginForm()),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
