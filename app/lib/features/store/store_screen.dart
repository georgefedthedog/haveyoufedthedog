import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_controller.dart';
import '../../core/household/current_household_controller.dart';
import '../../core/store/purchase_controller.dart';
import '../../core/store/store_controller.dart';
import '../../core/store/store_product.dart';

/// The pack shop. Lists purchasable products (a `catalog_products` row + live
/// store price), each previewing the packs it unlocks. Buying verifies the
/// receipt server-side and applies the packs to the current household; a
/// Restore action re-grants previously-bought packs.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface purchase outcomes as snackbars as they settle.
    ref.listen(purchaseControllerProvider, (_, next) {
      if (next.phase == PurchasePhase.success ||
          next.phase == PurchasePhase.error) {
        final msg = next.message;
        if (msg != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(showCloseIcon: true, content: Text(msg)));
        }
      }
    });

    final asyncProducts = ref.watch(storeProductsProvider);
    final busy = ref.watch(purchaseControllerProvider).phase ==
        PurchasePhase.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Art gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore purchases',
            onPressed: busy
                ? null
                : () => ref.read(purchaseControllerProvider.notifier).restore(),
          ),
        ],
      ),
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message("Couldn't load the shop.\n$e"),
        data: (products) {
          if (products.isEmpty) {
            return const _Message('No packs available yet.\nCheck back soon!');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _ProductCard(product: products[i], busy: busy),
          );
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final StoreProduct product;

  /// Any purchase in flight - disables Buy across all cards.
  final bool busy;

  const _ProductCard({required this.product, required this.busy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = ref.watch(catalogProvider);
    final household = ref.watch(currentHouseholdControllerProvider).valueOrNull;
    final householdPacks = household?.packIds ?? const <String>[];

    // Owned once the household already holds every pack this product grants.
    final owned = product.packIds.isNotEmpty &&
        product.packIds.every(householdPacks.contains);

    final progress = ref.watch(purchaseControllerProvider);
    final thisPending = progress.phase == PurchasePhase.pending &&
        progress.sku == product.sku;

    // Resolvable pack names (enabled packs only) - what the buyer unlocks.
    final includes = [for (final id in product.packIds) ?catalog.packName(id)];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.heroImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: product.heroImage.toString(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              product.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (includes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in includes)
                    Chip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (owned)
              _OwnedPill(scheme: scheme)
            else
              FilledButton.icon(
                icon: thisPending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(thisPending ? 'Working…' : 'Buy  ${product.price}'),
                onPressed: busy
                    ? null
                    : () =>
                        ref.read(purchaseControllerProvider.notifier).buy(product),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnedPill extends StatelessWidget {
  final ColorScheme scheme;
  const _OwnedPill({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          'Owned',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
