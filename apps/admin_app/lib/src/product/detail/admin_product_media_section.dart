import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Ordered product gallery matching Medusa's media card.
final class AdminProductMediaSection extends StatelessWidget {
  /// Creates the product media section.
  const AdminProductMediaSection({
    required this.product,
    required this.onUnavailable,
    super.key,
  });

  /// Complete admin product allowlist.
  final AdminProductDetail product;

  /// Reports controls whose write API is not implemented yet.
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: 'Media',
        action: adminSectionAction(onUnavailable),
        padding: const EdgeInsets.all(16),
        child: product.images.isEmpty
            ? const Center(child: Text('No media'))
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final image in product.images)
                    _MediaTile(
                      image: image,
                      thumbnail: image.url == product.thumbnail,
                    ),
                ],
              ),
      );
}

final class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.image, required this.thumbnail});

  final AdminProductImage image;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 108,
              height: 108,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.network(
                image.url,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
              ),
            ),
          ),
          if (thumbnail)
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 4),
                  ],
                ),
                child: const Icon(Icons.photo_size_select_actual_outlined,
                    size: 13),
              ),
            ),
        ],
      );
}
