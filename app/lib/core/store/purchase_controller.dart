import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../household/current_household_controller.dart';
import '../household/household_actions.dart';
import '../l10n/app_localizations_provider.dart';
import 'store_product.dart';

part 'purchase_controller.g.dart';

/// Where a purchase flow currently sits. (Distinct from the plugin's own
/// `PurchaseStatus` enum, which describes a single store transaction.)
enum PurchasePhase { idle, pending, success, error }

/// The controller's UI-facing state. [sku] identifies which product the phase
/// is about (so a card can show its own spinner); [message] carries the
/// snackbar text for success/error.
class PurchaseProgress {
  final PurchasePhase phase;
  final String? sku;
  final String? message;

  const PurchaseProgress(this.phase, {this.sku, this.message});

  static const idle = PurchaseProgress(PurchasePhase.idle);
}

/// Owns the single app-wide subscription to the in-app-purchase stream and
/// drives buy / restore. **Mounted for the app's lifetime** (watched at the
/// app root) so purchases that complete out-of-band - a slow card auth, or a
/// Restore - are verified and granted even if the user isn't on the store
/// screen at the time.
///
/// The store transaction carries no household, so entitlement is applied to
/// the *current* household when the event is processed - matching the
/// household-scoped ownership model (and the redeem-pack-code flow).
@Riverpod(keepAlive: true)
class PurchaseController extends _$PurchaseController {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  PurchaseProgress build() {
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) =>
          state = PurchaseProgress(PurchasePhase.error, message: '$e'),
    );
    ref.onDispose(() => _sub?.cancel());
    return PurchaseProgress.idle;
  }

  /// Kicks off a purchase. Success/failure arrives asynchronously via the
  /// purchase stream ([_onPurchases]), not from this call.
  Future<void> buy(StoreProduct product) async {
    state = PurchaseProgress(PurchasePhase.pending, sku: product.sku);
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product.details),
      );
      if (!started) {
        state = PurchaseProgress(
          PurchasePhase.error,
          sku: product.sku,
          // Purchase events arrive with no widget in scope, so this
          // controller resolves copy via appLocalizationsProvider.
          message: ref.read(appLocalizationsProvider).purchaseCouldNotStart,
        );
      }
    } catch (e) {
      state = PurchaseProgress(
        PurchasePhase.error,
        sku: product.sku,
        message: '$e',
      );
    }
  }

  /// Restores previously-bought packs. Restored items flow through the stream
  /// and are re-verified + re-applied to the current household.
  Future<void> restore() async {
    state = const PurchaseProgress(PurchasePhase.pending);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      state = PurchaseProgress(PurchasePhase.error, message: '$e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      // Whether to acknowledge/finish the transaction with the store. We only
      // finalize a successful (or terminal) purchase - never a purchased item
      // whose server-side grant failed, so it can be retried.
      var finalize = false;

      switch (p.status) {
        case PurchaseStatus.pending:
          state = PurchaseProgress(PurchasePhase.pending, sku: p.productID);
        case PurchaseStatus.error:
          state = PurchaseProgress(
            PurchasePhase.error,
            sku: p.productID,
            message:
                p.error?.message ??
                ref.read(appLocalizationsProvider).purchaseFailed,
          );
          finalize = true; // dead transaction - clear it
        case PurchaseStatus.canceled:
          state = PurchaseProgress(PurchasePhase.idle, sku: p.productID);
          finalize = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Only finalize once the server has actually granted. A failed
          // verify (transient error, or the Play service-account permission
          // still propagating) then leaves the purchase un-acknowledged, so
          // Play re-delivers it and a later Buy/Restore retries - rather than
          // acknowledging a purchase the user never received.
          finalize = await _verifyAndGrant(p);
      }

      if (finalize && p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  /// Verifies the purchase server-side and applies its packs to the current
  /// household. Returns true only when the grant succeeded (or was already
  /// applied) - the caller uses this to decide whether to finalize the
  /// transaction with the store.
  Future<bool> _verifyAndGrant(PurchaseDetails p) async {
    final household = ref.read(currentHouseholdControllerProvider).valueOrNull;
    if (household == null) {
      // No household to grant to yet - leave the purchase pending so it
      // retries once one is active.
      state = PurchaseProgress(
        PurchasePhase.error,
        sku: p.productID,
        message: ref.read(appLocalizationsProvider).purchaseNeedHousehold,
      );
      return false;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      final result = await ref
          .read(householdActionsProvider)
          .verifyAndApplyPurchase(
            householdId: household.id,
            platform: platform,
            sku: p.productID,
            // For Android this is the purchase token; for iOS, the receipt.
            purchaseToken: p.verificationData.serverVerificationData,
          );
      final l10n = ref.read(appLocalizationsProvider);
      state = PurchaseProgress(
        PurchasePhase.success,
        sku: p.productID,
        message: result.alreadyApplied
            ? l10n.purchaseAlreadyUnlocked(result.name)
            : l10n.purchaseUnlocked(result.name),
      );
      return true;
    } on ClientException catch (e) {
      state = PurchaseProgress(
        PurchasePhase.error,
        sku: p.productID,
        message:
            e.response['message'] as String? ??
            ref.read(appLocalizationsProvider).purchaseVerifyFailed,
      );
      return false;
    } catch (e) {
      state = PurchaseProgress(
        PurchasePhase.error,
        sku: p.productID,
        message: '$e',
      );
      return false;
    }
  }
}
