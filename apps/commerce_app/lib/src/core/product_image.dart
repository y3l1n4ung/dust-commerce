import 'package:commerce_app/src/core/store_theme.dart';
import 'package:flutter/material.dart';

/// A source-backed product image with explicit loading and failure states.
class ProductImage extends StatelessWidget {
  /// Creates a product image.
  const ProductImage({
    required this.url,
    this.aspectRatio = 11 / 14,
    this.border = true,
    this.placeholderColor,
    this.placeholderSize,
    this.semanticLabel,
    super.key,
  });

  /// Width-to-height ratio of the Medusa image slot.
  final double aspectRatio;

  /// Whether the image slot draws the default storefront border.
  final bool border;

  /// Optional placeholder icon color for source-specific thumbnail slots.
  final Color? placeholderColor;

  /// Optional placeholder icon size for source-specific thumbnail slots.
  final double? placeholderSize;

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
          border: border ? Border.all(color: StoreColors.border) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: source == null
              ? Semantics(
                  label: semanticLabel,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: placeholderColor,
                      size: placeholderSize,
                    ),
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
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: placeholderColor,
                        size: placeholderSize,
                      ),
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
