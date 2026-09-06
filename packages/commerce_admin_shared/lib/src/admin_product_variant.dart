import 'package:dust_dart/serde.dart';

part 'admin_product_variant.g.dart';

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
    this.barcode,
  });

  /// Decodes one generated admin variant response.
  factory AdminProductVariant.fromJson(Map<String, Object?> json) =>
      _$AdminProductVariantFromJson(json);

  /// Whether selling beyond tracked stock is allowed.
  final bool allowBackorder;

  /// Optional machine-readable product identifier.
  final String? barcode;

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

/// Complete replacement of the variant fields edited in Medusa's detail drawer.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminUpdateProductVariant with _$AdminUpdateProductVariant {
  /// Creates one validated merchant variant update.
  const AdminUpdateProductVariant({
    required this.title,
    required this.manageInventory,
    required this.allowBackorder,
    required this.optionValues,
    this.sku,
    this.barcode,
  });

  /// Decodes the generated variant input.
  factory AdminUpdateProductVariant.fromJson(Map<String, Object?> json) =>
      _$AdminUpdateProductVariantFromJson(json);

  /// Whether sales may continue after tracked stock is exhausted.
  final bool allowBackorder;

  /// Optional machine-readable product identifier; an empty value clears it.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? barcode;

  /// Whether checkout enforces this variant's inventory quantity.
  final bool manageInventory;

  /// Selected value keyed by stable product-option identifier.
  final Map<String, String> optionValues;

  /// Optional unique merchant stock identifier; an empty value clears it.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? sku;

  /// Required merchant-facing variant name.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter a variant name')
  @Validate(regex: r'.*\S.*', message: 'Enter a variant name')
  final String title;
}
