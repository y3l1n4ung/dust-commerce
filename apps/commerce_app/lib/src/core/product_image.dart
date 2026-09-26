import 'package:commerce_app/src/core/store_theme.dart';
import 'package:flutter/material.dart';

/// A source-backed product image with explicit loading and failure states.
class ProductImage extends StatelessWidget {
  /// Creates a product image.
  const ProductImage({
    required this.url,
    this.aspectRatio = 11 / 14,
    this.semanticLabel,
    super.key,
  });

  /// Width-to-height ratio of the Medusa image slot.
  final double aspectRatio;

  /// Optional accessible label for standalone product imagery.
  final String? semanticLabel;

  /// Remote merchant image URL.
  final String? url;

  @override
  Widget build(BuildContext context) {
    final source = url;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoreColors.subtle,
          border: Border.all(color: StoreColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: source == null
              ? Semantics(
                  label: semanticLabel,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                )
              : Image.network(
                  source,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                  // Medusa's public seed CDN omits CORS headers. An HTML image
                  // keeps merchant-hosted assets usable on web; native targets
                  // continue through Flutter's byte-based network loader.
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) => Semantics(
                    label: semanticLabel,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}
