import 'package:commerce_server/src/features/catalog/json_converters.dart';
import 'package:commerce_server/src/features/catalog/option_response.dart';
import 'package:commerce_server/src/features/catalog/variant_response.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'model.g.dart';

/// Explicit storefront product response populated directly by SQLx.
///
/// This does not extend the domain product. Every serialized field is declared
/// here, so adding an internal field to [Product] cannot widen the API.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class ProductResponse with _$ProductResponse {
  /// Creates one complete product response.
  const ProductResponse({
    required this.id,
    required this.title,
    required this.handle,
    required this.status,
    required this.details,
    required this.categories,
    required this.images,
    required this.options,
    required this.tags,
    required this.variants,
    this.collection,
    this.description,
    this.thumbnail,
  });

  /// Long-form storefront copy.
  final String? description;

  /// Explicit public categories attached to the product.
  @Sqlx(tryFrom: ProductCategoriesFromJson())
  final List<ProductCategory> categories;

  /// Explicit public collection, absent when the product is ungrouped.
  @Sqlx(tryFrom: ProductCollectionFromJson())
  final ProductCollection? collection;

  /// Physical and merchandising facts approved for the storefront.
  @Sqlx(tryFrom: ProductDetailsFromJson())
  final ProductDetails details;

  /// Stable customer-facing route segment.
  final String handle;

  /// Stable product identifier.
  final String id;

  /// Ordered gallery image URLs.
  @Sqlx(tryFrom: ProductImagesFromJson())
  final List<String> images;

  /// Explicit variant axes approved for the storefront.
  @Sqlx(tryFrom: ProductOptionsFromJson())
  final List<ProductOptionResponse> options;

  /// Public lifecycle status as its stable wire value.
  final String status;

  /// Explicit public discovery labels attached to the product.
  @Sqlx(tryFrom: ProductTagsFromJson())
  final List<ProductTag> tags;

  /// Customer-facing product name.
  final String title;

  /// Primary storefront image.
  final String? thumbnail;

  /// Currency-scoped buyable configurations.
  @Sqlx(tryFrom: ProductVariantsFromJson())
  final List<ProductVariantResponse> variants;
}

/// Explicit paginated product response.
@Derive([Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class ProductPageResponse with _$ProductPageResponse {
  /// Creates a page response from complete products.
  const ProductPageResponse({
    required this.products,
    required this.count,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Number of products in this response.
  final int count;

  /// Requested page size.
  final int limit;

  /// Number of products skipped.
  final int offset;

  /// Explicit product response allowlists.
  final List<ProductResponse> products;

  /// Number of published products in the catalogue.
  final int total;
}
