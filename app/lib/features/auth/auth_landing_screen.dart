import 'package:flutter/material.dart';

import 'login_form.dart';
import 'signup_form.dart';

/// Tabbed entry point for unauthenticated users. Login on the left,
/// Sign up on the right. The router redirects here whenever the user is
/// signed out.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Have You Fed The Dog?'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Log in'),
              Tab(text: 'Sign up'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [LoginForm(), SignupForm()],
          ),
        ),
      ),
    );
  }
}
