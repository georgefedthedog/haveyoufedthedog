import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import '../l10n/name_i18n.dart';
import 'store_product.dart';

part 'store_controller.g.dart';

/// The products for sale: enabled `catalog_products` rows merged with their
/// live store listings.
///
/// **A product only appears if the store also knows its SKU** - so until the
/// Play / App Store products are configured and approved, this is empty even
/// though the PB rows exist. Fail-soft: a store that's unavailable (no
/// billing, offline, signed out) yields an empty list rather than an error,
/// so the storefront just shows "nothing for sale" instead of breaking.
///
/// autoDispose (default): refetched each time the store screen opens so prices
/// and availability stay current.
@riverpod
Future<List<StoreProduct>> storeProducts(Ref ref) async {
  final pb = await ref.watch(pocketbaseClientProvider.future);
  final userId = await ref.watch(
    authControllerProvider.selectAsync((a) => a.userId),
  );
  if (userId == null) return const [];

  final rows = await pb
      .collection('catalog_products')
      .getFullList(filter: 'enabled = true', sort: 'sort_order,created');
  if (rows.isEmpty) return const [];

  final detailsBySku = await _storeDetails(rows);

  return [
    for (final r in rows)
      if (detailsBySku[r.getStringValue('sku')] case final d?)
        _productFrom(pb, r, d),
  ];
}

/// Queries the platform store for live [ProductDetails] keyed by SKU. Returns
/// empty when in-app purchases aren't available (no billing on device, store
/// misconfigured) so callers simply show nothing for sale.
Future<Map<String, ProductDetails>> _storeDetails(
  List<RecordModel> rows,
) async {
  final iap = InAppPurchase.instance;
  if (!await iap.isAvailable()) {
    debugPrint('Store: in-app purchases unavailable on this device.');
    return const {};
  }

  final skus = <String>{
    for (final r in rows)
      if (r.getStringValue('sku').isNotEmpty) r.getStringValue('sku'),
  };
  if (skus.isEmpty) return const {};

  final resp = await iap.queryProductDetails(skus);
  if (resp.error != null) {
    debugPrint('Store: price query error - ${resp.error}');
  }
  if (resp.notFoundIDs.isNotEmpty) {
    debugPrint('Store: no store listing for SKUs ${resp.notFoundIDs}');
  }
  return {for (final d in resp.productDetails) d.id: d};
}

StoreProduct _productFrom(
  PocketBase pb,
  RecordModel r,
  ProductDetails details,
) {
  final hero = r.getStringValue('hero_image');
  return StoreProduct(
    id: r.id,
    sku: r.getStringValue('sku'),
    name: r.getStringValue('name'),
    description: r.getStringValue('description'),
    packIds: r.getListValue<String>('grants'),
    heroImage: hero.isEmpty ? null : pb.files.getUrl(r, hero),
    sortOrder: r.getIntValue('sort_order'),
    details: details,
    nameI18n: nameI18nFromJson(r.data['name_i18n']),
    descriptionI18n: nameI18nFromJson(r.data['description_i18n']),
  );
}
