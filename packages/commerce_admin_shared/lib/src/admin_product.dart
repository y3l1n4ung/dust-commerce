import 'package:dust_dart/serde.dart';

part 'admin_product.g.dart';

/// One explicitly allowlisted product row in the merchant catalogue.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProduct with _$AdminProduct {
  /// Creates a merchant-facing product summary.
  const AdminProduct({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.collectionTitle,
    required this.salesChannels,
    required this.variantCount,
    required this.status,
  });

  /// Decodes the admin API response using Dust.
  factory AdminProduct.fromJson(Map<String, Object?> json) =>
      _$AdminProductFromJson(json);

  /// Collection label, empty when the product is not grouped.
  final String collectionTitle;

  /// Stable product identifier used by future admin detail routes.
  final String id;

  /// Sales-channel summary, empty until channel management is implemented.
  final String salesChannels;

  /// Merchant lifecycle state.
  final String status;

  /// Primary image URL, empty when the product has no thumbnail.
  final String thumbnail;

  /// Merchant-facing product name.
  final String title;

  /// Number of active variants attached to the product.
  final int variantCount;
}

/// A bounded product page returned by the merchant API.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductList with _$AdminProductList {
  /// Creates an admin product page.
  const AdminProductList({
    required this.products,
    required this.count,
    required this.limit,
    required this.offset,
  });

  /// Decodes the generated admin response.
  factory AdminProductList.fromJson(Map<String, Object?> json) =>
      _$AdminProductListFromJson(json);

  /// Total number of products matching the query.
  final int count;

  /// Maximum rows requested for this page.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Products in stable newest-first order.
  final List<AdminProduct> products;
}

/// One image intentionally exposed to the merchant product detail.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductImage with _$AdminProductImage {
  /// Creates an ordered merchant image.
  const AdminProductImage({required this.id, required this.url});

  /// Decodes one generated admin image response.
  factory AdminProductImage.fromJson(Map<String, Object?> json) =>
      _$AdminProductImageFromJson(json);

  /// Stable image identifier used by future media mutations.
  final String id;

  /// Merchant asset URL.
  final String url;
}

/// One selectable product dimension and its ordered values.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductOption with _$AdminProductOption {
  /// Creates an explicitly allowlisted merchant option.
  const AdminProductOption({
    required this.id,
    required this.title,
    required this.values,
  });

  /// Decodes one generated admin option response.
  factory AdminProductOption.fromJson(Map<String, Object?> json) =>
      _$AdminProductOptionFromJson(json);

  /// Stable option identifier.
  final String id;

  /// Merchant-facing dimension name.
  final String title;

  /// Values in merchant-defined display order.
  final List<String> values;
}

/// One inventory-bearing variant shown in the admin detail table.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductVariant with _$AdminProductVariant {
  /// Creates an explicitly allowlisted merchant variant.
  const AdminProductVariant({
    required this.id,
    required this.title,
    required this.inventoryQuantity,
    required this.manageInventory,
    required this.allowBackorder,
    required this.optionValues,
    this.sku,
  });

  /// Decodes one generated admin variant response.
  factory AdminProductVariant.fromJson(Map<String, Object?> json) =>
      _$AdminProductVariantFromJson(json);

  /// Whether selling beyond tracked stock is allowed.
  final bool allowBackorder;

  /// Stable variant identifier.
  final String id;

  /// Current sellable units.
  final int inventoryQuantity;

  /// Whether this variant uses inventory enforcement.
  final bool manageInventory;

  /// Selected value keyed by product-option identifier.
  final Map<String, String> optionValues;

  /// Optional merchant stock-keeping unit.
  final String? sku;

  /// Merchant-facing variant name.
  final String title;
}

/// Complete allowlisted merchant product detail.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductDetail with _$AdminProductDetail {
  /// Creates one product detail without inheriting database internals.
  const AdminProductDetail({
    required this.id,
    required this.title,
    required this.handle,
    required this.status,
    required this.images,
    required this.options,
    required this.variants,
    required this.categories,
    required this.tags,
    this.description,
    this.thumbnail,
    this.material,
    this.originCountry,
    this.productType,
    this.collectionTitle,
    this.weight,
    this.length,
    this.width,
    this.height,
  });

  /// Decodes the generated admin detail response.
  factory AdminProductDetail.fromJson(Map<String, Object?> json) =>
      _$AdminProductDetailFromJson(json);

  /// Public categories assigned to the product.
  final List<String> categories;

  /// Optional curated collection label.
  final String? collectionTitle;

  /// Optional long-form merchant description.
  final String? description;

  /// Optional height in the store's configured unit.
  final int? height;

  /// Stable storefront route segment.
  final String handle;

  /// Stable product identifier.
  final String id;

  /// Ordered merchant media.
  final List<AdminProductImage> images;

  /// Optional length in the store's configured unit.
  final int? length;

  /// Optional merchant material description.
  final String? material;

  /// Ordered selectable dimensions.
  final List<AdminProductOption> options;

  /// Optional ISO 3166-1 alpha-2 country code.
  final String? originCountry;

  /// Optional merchant product classification.
  final String? productType;

  /// Merchant lifecycle state.
  final String status;

  /// Public discovery tags assigned to the product.
  final List<String> tags;

  /// Optional primary merchant image.
  final String? thumbnail;

  /// Merchant-facing product name.
  final String title;

  /// Inventory-bearing variants.
  final List<AdminProductVariant> variants;

  /// Optional weight in the store's configured unit.
  final int? weight;

  /// Optional width in the store's configured unit.
  final int? width;
}
