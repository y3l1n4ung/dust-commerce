import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:admin_app/src/product/detail/admin_product_sales_channel_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped product sidebar backed only by modeled product data.
final class AdminProductSidebarSections extends StatelessWidget {
  /// Creates product sidebar cards.
  const AdminProductSidebarSections({
    required this.product,
    required this.salesChannels,
    required this.totalSalesChannels,
    required this.onEditOrganization,
    required this.onEditSalesChannels,
    required this.onUnavailable,
    super.key,
  });

  /// Complete admin product allowlist.
  final AdminProductDetail product;

  /// Channels through which this product is available.
  final List<AdminSalesChannel> salesChannels;

  /// Total configured channels, absent when the supporting request failed.
  final Option<int> totalSalesChannels;

  /// Opens the product-type organization editor.
  final VoidCallback onEditOrganization;

  /// Opens the product sales-channel focus editor.
  final VoidCallback onEditSalesChannels;

  /// Reports controls whose domain is not implemented yet.
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AdminProductSalesChannelSection(
            channels: salesChannels,
            totalChannels: totalSalesChannels,
            onEdit: onEditSalesChannels,
          ),
          const SizedBox(height: 12),
          _UnavailableSection(
            title: 'Shipping configuration',
            icon: Icons.shopping_bag_outlined,
            message: 'Not configured',
            onUnavailable: onUnavailable,
          ),
          const SizedBox(height: 12),
          AdminProductDetailSection(
            title: 'Organize',
            action: adminSectionAction(onEditOrganization),
            child: Column(
              children: [
                _badges(context, 'Tags', product.tags),
                _badges(context, 'Type', [product.productType ?? '']),
                _badges(
                  context,
                  'Collection',
                  [product.collectionTitle ?? ''],
                ),
                _badges(context, 'Categories', product.categories),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdminProductDetailSection(
            title: 'Attributes',
            action: adminSectionAction(onUnavailable),
            child: Column(
              children: [
                _row(context, 'Height', product.height),
                _row(context, 'Width', product.width),
                _row(context, 'Length', product.length),
                _row(context, 'Weight', product.weight),
                _row(context, 'Country of Origin', product.originCountry),
              ],
            ),
          ),
        ],
      );

  Widget _row(BuildContext context, String label, Object? value) =>
      AdminProductDetailRow(
        label: label,
        value: adminDetailText(context, value),
      );

  Widget _badges(BuildContext context, String label, List<String> values) {
    final present = values.where((value) => value.trim().isNotEmpty).toList();
    return AdminProductDetailRow(
      label: label,
      value: present.isEmpty
          ? adminDetailText(context, null)
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final value in present) _Badge(value: value)],
            ),
    );
  }
}

final class _UnavailableSection extends StatelessWidget {
  const _UnavailableSection({
    required this.title,
    required this.icon,
    required this.message,
    required this.onUnavailable,
  });

  final IconData icon;
  final String message;
  final VoidCallback onUnavailable;
  final String title;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: title,
        action: adminSectionAction(onUnavailable),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

final class _Badge extends StatelessWidget {
  const _Badge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodySmall),
      );
}
