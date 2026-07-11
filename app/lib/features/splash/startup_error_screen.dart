import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/household/households_controller.dart';
import '../../l10n/l10n.dart';

/// Shown when the app can't resolve its startup state - the auth snapshot or
/// the initial households fetch errored (typically the server is unreachable).
///
/// Replaces what used to be an indefinite splash spinner with an explicit
/// retry. Retrying invalidates the auth + households providers; households
/// watches auth, so this rebuilds the whole startup chain and the routing
/// phase re-derives (dropping back through splash) once they resolve.
class StartupErrorScreen extends ConsumerWidget {
  const StartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/subjects/dog/sad.png',
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.startupErrorTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.startupErrorBody,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.invalidate(authControllerProvider);
                  ref.invalidate(householdsControllerProvider);
                },
                child: Text(context.l10n.commonTryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
