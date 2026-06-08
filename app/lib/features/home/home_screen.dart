import 'package:flutter/material.dart';

import '../../widgets/build_label.dart';

/// Placeholder home screen for Step 1. Will be replaced when the real home
/// (subjects list) lands in Step 6.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Have You Fed The Dog?')),
      body: const Center(child: Text('Skeleton — nothing here yet.')),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}
