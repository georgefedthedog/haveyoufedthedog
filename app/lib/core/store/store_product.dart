import 'package:in_app_purchase/in_app_purchase.dart';

/// A purchasable product: a `catalog_products` row merged with its live store
/// listing (localized price, etc.). Only products the store can actually sell
/// reach this type, so [details] is always present.
///
/// One product grants one-or-more packs ([packIds]) - a single themed pack, or
/// several for a bundle. Buying it appends those pack ids to the household's
/// `packs` relation server-side, after receipt verification.
class StoreProduct {
  /// PB `catalog_products` record id.
  final String id;

  /// Store product id - matches the SKU configured in Play / App Store.
  final String sku;

  /// Display name from PB. (The store also exposes a title via
  /// [details.title]; we use our own copy for consistent branding.)
  final String name;

  final String description;

  /// `catalog_packs` ids this product unlocks when purchased.
  final List<String> packIds;

  /// Optional storefront art.
  final Uri? heroImage;

  final int sortOrder;

  /// Live store listing - the source of the localized [price] and what the
  /// purchase flow hands to `buyNonConsumable`.
  final ProductDetails details;

  const StoreProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.packIds,
    required this.heroImage,
    required this.sortOrder,
    required this.details,
  });

  /// Localized price string, e.g. "£2.99" - formatted by the store for the
  /// user's region and currency.
  String get price => details.price;
}
