import 'dart:convert';

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
    required this.images,
    required this.options,
    required this.variants,
    this.description,
    this.thumbnail,
  });

  /// Long-form storefront copy.
  final String? description;

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

/// Decodes the public detail object selected as JSON.
final class ProductDetailsFromJson
    implements SqlxTryFrom<ProductDetails, String> {
  /// Creates the stateless converter.
  const ProductDetailsFromJson();

  @override
  ProductDetails decode(String value) =>
      ProductDetails.fromJson(_object(value));
}

/// Decodes ordered product image URLs selected as JSON.
final class ProductImagesFromJson implements SqlxTryFrom<List<String>, String> {
  /// Creates the stateless converter.
  const ProductImagesFromJson();

  @override
  List<String> decode(String value) => [
        for (final item in _array(value)) item! as String,
      ];
}

/// Decodes explicit public product options selected as JSON.
final class ProductOptionsFromJson
    implements SqlxTryFrom<List<ProductOptionResponse>, String> {
  /// Creates the stateless converter.
  const ProductOptionsFromJson();

  @override
  List<ProductOptionResponse> decode(String value) => [
        for (final item in _array(value))
          _option(item! as Map<String, Object?>),
      ];

  static ProductOptionResponse _option(Map<String, Object?> item) =>
      ProductOptionResponse(
        id: item['id']! as String,
        title: item['title']! as String,
        values: (item['values_csv']! as String)
            .split(',')
            .where((choice) => choice.isNotEmpty)
            .toList(growable: false),
      );
}

/// Decodes currency-scoped public variants selected as JSON.
final class ProductVariantsFromJson
    implements SqlxTryFrom<List<ProductVariantResponse>, String> {
  /// Creates the stateless converter.
  const ProductVariantsFromJson();

  @override
  List<ProductVariantResponse> decode(String value) => [
        for (final item in _array(value))
          _variant(item! as Map<String, Object?>),
      ];

  static ProductVariantResponse _variant(Map<String, Object?> value) =>
      ProductVariantResponse(
        id: value['id']! as String,
        title: value['title']! as String,
        sku: value['sku'] as String?,
        prices: [
          Money(
            amount: value['amount']! as int,
            currencyCode: value['currency_code']! as String,
          ),
        ],
        inventoryQuantity: value['inventory_quantity']! as int,
        manageInventory: value['manage_inventory']! as int != 0,
        allowBackorder: value['allow_backorder']! as int != 0,
        optionValues: (value['option_values']! as Map<String, Object?>).map(
          (key, choice) => MapEntry(key, choice! as String),
        ),
      );
}

List<Object?> _array(String value) => jsonDecode(value) as List<Object?>;

Map<String, Object?> _object(String value) =>
    jsonDecode(value) as Map<String, Object?>;
