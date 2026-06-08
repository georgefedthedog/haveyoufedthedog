import 'package:flutter/material.dart';

/// Shown while critical auth / household state is being resolved. The
/// router's redirect logic will move us away as soon as state settles.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
