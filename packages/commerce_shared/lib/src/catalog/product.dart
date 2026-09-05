import 'package:commerce_shared/src/catalog/option.dart';
import 'package:commerce_shared/src/catalog/variant.dart';
import 'package:commerce_shared/src/money.dart';
import 'package:dust_dart/serde.dart';

part 'product.g.dart';

/// Where a product sits in its publishing lifecycle.
///
/// Only [published] is visible to a storefront. The other three exist so an
/// operator can stage work without it leaking into the catalogue.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum ProductStatus {
  /// Being written; never listed, never purchasable.
  draft,

  /// Submitted for review.
  proposed,

  /// Live in the storefront.
  published,

  /// Reviewed and refused.
  rejected;

  /// Whether a storefront should list a product in this state.
  bool get isVisible => this == ProductStatus.published;
}

/// A sellable item, and the options its variants vary along.
///
/// A product is not itself buyable — its variants are. The product holds what
/// is common: the name the storefront shows, the handle it routes on, and the
/// axes along which the variants differ.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class Product with _$Product {
  /// Creates a [Product] from already-validated values.
  const Product({
    required this.id,
    required this.title,
    required this.handle,
    required this.status,
    required this.options,
    required this.variants,
    this.description,
    this.thumbnail,
  });

  /// Creates a [Product], checking every variant against the declared options.
  ///
  /// Throws [ArgumentError] when two variants share an id, or when a variant
  /// chooses an option value the product does not offer — a combination
  /// nothing could ever render or price.
  factory Product.of({
    required String id,
    required String title,
    required String handle,
    ProductStatus status = ProductStatus.draft,
    String? description,
    String? thumbnail,
    List<ProductOption> options = const [],
    List<ProductVariant> variants = const [],
  }) {
    final ids = variants.map((variant) => variant.id).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(variants, 'variants', 'duplicate variant id');
    }
    for (final variant in variants) {
      _checkOptions(variant, options);
    }
    return Product(
      id: id,
      title: title,
      handle: _slugify(handle),
      status: status,
      description: description,
      thumbnail: thumbnail,
      options: options,
      variants: variants,
    );
  }

  /// Creates a [Product] from JSON.
  factory Product.fromJson(Map<String, Object?> json) =>
      _$ProductFromJson(json);

  /// Long-form copy.
  final String? description;

  /// URL-safe identifier the storefront routes on.
  final String handle;

  /// Unique identifier.
  final String id;

  /// The axes the variants vary along.
  final List<ProductOption> options;

  /// Publishing state.
  final ProductStatus status;

  /// Display name.
  final String title;

  /// Primary image.
  final String? thumbnail;

  /// The buyable configurations.
  final List<ProductVariant> variants;

  /// Whether a customer can buy this right now.
  ///
  /// Published and at least one variant in stock. A published product whose
  /// every variant has sold out is listed but not purchasable, which is the
  /// distinction a storefront needs to show "sold out" rather than hide it.
  bool get isPurchasable =>
      status.isVisible && variants.any((variant) => variant.isInStock);

  /// The lowest price across variants in [currencyCode], or null.
  Money? cheapestIn(String currencyCode) {
    Money? cheapest;
    for (final variant in variants) {
      final price = variant.priceIn(currencyCode);
      if (price == null) continue;
      if (cheapest == null || price < cheapest) cheapest = price;
    }
    return cheapest;
  }

  /// The variant with [id], or null.
  ProductVariant? variantById(String id) {
    for (final variant in variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  /// The variant matching every option value in [selection], or null.
  ProductVariant? variantFor(Map<String, String> selection) {
    for (final variant in variants) {
      final matches = selection.entries.every(
        (choice) => variant.optionValues[choice.key] == choice.value,
      );
      if (matches) return variant;
    }
    return null;
  }

  static void _checkOptions(
    ProductVariant variant,
    List<ProductOption> options,
  ) {
    for (final choice in variant.optionValues.entries) {
      final option = options.where((it) => it.id == choice.key).firstOrNull;
      if (option == null) {
        throw ArgumentError.value(
          choice.key,
          'variants',
          'variant ${variant.id} names an option the product does not declare',
        );
      }
      if (!option.offers(choice.value)) {
        throw ArgumentError.value(
          choice.value,
          'variants',
          'option ${option.title} does not offer this value',
        );
      }
    }
  }

  static final RegExp _separators = RegExp(r'[^a-z0-9]+');

  static String _slugify(String handle) {
    final slug = handle
        .toLowerCase()
        .replaceAll(_separators, '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      throw ArgumentError.value(handle, 'handle', 'leaves nothing to route on');
    }
    return slug;
  }
}
