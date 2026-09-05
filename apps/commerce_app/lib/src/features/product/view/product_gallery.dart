import 'package:commerce_app/src/core/product_image.dart';
import 'package:flutter/material.dart';

/// Ordered image stack translated from Medusa DTC `ImageGallery`.
class ProductGallery extends StatelessWidget {
  /// Creates a product gallery.
  const ProductGallery({
    required this.urls,
    required this.fallbackUrl,
    super.key,
  });

  /// Primary image used by older catalog records without gallery rows.
  final String? fallbackUrl;

  /// Ordered merchant image URLs.
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final images = urls.isEmpty ? [fallbackUrl] : urls;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var index = 0; index < images.length; index++) ...[
            ProductImage(url: images[index], aspectRatio: 29 / 34),
            if (index != images.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
