// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authControllerHash() => r'7482deecb064b835fb7de50ce1f5c1efbf41a9c1';

/// Tracks the current PB auth state and exposes login / signup / logout.
///
/// `build()` is synchronous on purpose — the PB client itself is bootstrapped
/// in `main()` so there is no async work to await here. That keeps Riverpod's
/// dependency tracking simple and avoids the build-cancellation bugs we hit
/// before.
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthController = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
