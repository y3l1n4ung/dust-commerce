import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Inventory variants matching Medusa's detail table shape.
final class AdminProductVariantSection extends StatelessWidget {
  /// Creates the variant table.
  const AdminProductVariantSection({
    required this.variants,
    required this.onUnavailable,
    super.key,
  });

  /// Inventory-bearing merchant variants.
  final List<AdminProductVariant> variants;

  /// Reports controls whose write API is not implemented yet.
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: 'Variants',
        action: OutlinedButton(
          onPressed: onUnavailable,
          child: const Text('Create'),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onUnavailable,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add filter'),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      onSubmitted: (_) => onUnavailable(),
                      decoration: const InputDecoration(
                        hintText: 'Search variants',
                        prefixIcon: Icon(Icons.search_rounded, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            if (variants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No variants'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 660,
                  child: Column(
                    children: [
                      const _VariantHeader(),
                      for (final variant in variants)
                        _VariantRow(variant: variant),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

final class _VariantHeader extends StatelessWidget {
  const _VariantHeader();

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: const Row(
          children: [
            Expanded(flex: 3, child: Text('Variant')),
            Expanded(flex: 2, child: Text('SKU')),
            Expanded(child: Text('Stock')),
            Expanded(child: Text('Inventory')),
          ],
        ),
      );
}

final class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.variant});

  final AdminProductVariant variant;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(variant.title)),
            Expanded(
              flex: 2,
              child: adminDetailText(context, variant.sku),
            ),
            Expanded(child: Text('${variant.inventoryQuantity}')),
            Expanded(
              child: Text(variant.manageInventory ? 'Managed' : 'Unmanaged'),
            ),
          ],
        ),
      );
}
