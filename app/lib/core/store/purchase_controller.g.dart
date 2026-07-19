// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$purchaseControllerHash() =>
    r'7e599a51b13ef917ac50f7d4067d198cd1592c9d';

/// Owns the single app-wide subscription to the in-app-purchase stream and
/// drives buy / restore. **Mounted for the app's lifetime** (watched at the
/// app root) so purchases that complete out-of-band - a slow card auth, or a
/// Restore - are verified and granted even if the user isn't on the store
/// screen at the time.
///
/// The store transaction carries no household, so entitlement is applied to
/// the *current* household when the event is processed - matching the
/// household-scoped ownership model (and the redeem-pack-code flow).
///
/// Copied from [PurchaseController].
@ProviderFor(PurchaseController)
final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseProgress>.internal(
      PurchaseController.new,
      name: r'purchaseControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchaseControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PurchaseController = Notifier<PurchaseProgress>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
