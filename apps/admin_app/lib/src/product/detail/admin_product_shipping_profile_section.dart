import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped scalar fulfillment profile section.
final class AdminProductShippingProfileSection extends StatelessWidget {
  /// Creates the product profile summary and edit affordance.
  const AdminProductShippingProfileSection({
    required this.shippingProfile,
    required this.onEdit,
    super.key,
  });

  /// Opens the right-side profile editor.
  final VoidCallback onEdit;

  /// Current profile selected by the product detail response.
  final Option<AdminShippingProfile> shippingProfile;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: 'Shipping Profile',
        action: adminSectionAction(onEdit),
        child: switch (shippingProfile) {
          Some(:final value) => _ShippingProfileLink(profile: value),
          None() => const SizedBox.shrink(),
        },
      );
}

final class _ShippingProfileLink extends StatelessWidget {
  const _ShippingProfileLink({required this.profile});

  final AdminShippingProfile profile;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name),
                  Text(
                    profile.type,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
}
