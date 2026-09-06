import 'package:commerce_admin_shared/src/admin_product_image.dart';
import 'package:commerce_admin_shared/src/admin_product_media.dart';
import 'package:dust_dart/serde.dart';

part 'admin_product.g.dart';

/// Merchant publishing state kept separate from the storefront contract.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum AdminProductLifecycle {
  /// Work in progress; hidden from customers.
  draft,

  /// Awaiting merchant approval; hidden from customers.
  proposed,

  /// Live and eligible for storefront discovery.
  published,

  /// Refused during merchant review; hidden from customers.
  rejected,
}

/// Public codec for server projections that serialize this package's enum.
final class AdminProductLifecycleCodec
    implements SerDeCodec<AdminProductLifecycle, String> {
  /// Creates the stateless lifecycle codec.
  const AdminProductLifecycleCodec();

  @override
  AdminProductLifecycle deserialize(String value) =>
      AdminProductLifecycle.values.byName(value);

  @override
  String serialize(AdminProductLifecycle value) => value.name;
}

/// One exact regional price supplied while creating a product variant.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminCreateProductPrice with _$AdminCreateProductPrice {
  /// Creates an integer-minor-unit price without floating-point money.
  const AdminCreateProductPrice({
    required this.currencyCode,
    required this.amount,
  });

  /// Decodes the generated price input.
  factory AdminCreateProductPrice.fromJson(Map<String, Object?> json) =>
      _$AdminCreateProductPriceFromJson(json);

  /// Exact amount in the currency's minor unit.
  @Validate(range: Range(min: 0), message: 'Enter a non-negative price')
  final int amount;

  /// Lowercase ISO 4217 currency configured by an active selling region.
  @Validate(length: Length(min: 3, max: 3), message: 'Choose a currency')
  @Validate(regex: r'^[a-z]{3}$', message: 'Choose a currency')
  final String currencyCode;
}

/// One product option and its merchant-ordered values at creation time.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminCreateProductOption with _$AdminCreateProductOption {
  /// Creates one selectable product dimension.
  const AdminCreateProductOption({
    required this.title,
    required this.values,
  });

  /// Decodes the generated option input.
  factory AdminCreateProductOption.fromJson(Map<String, Object?> json) =>
      _$AdminCreateProductOptionFromJson(json);

  /// Merchant-facing dimension name, such as Size.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter an option name')
  @Validate(regex: r'.*\S.*', message: 'Enter an option name')
  final String title;

  /// Ordered values offered for this dimension.
  final List<String> values;
}

/// One sellable product variant created atomically with its parent product.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminCreateProductVariant with _$AdminCreateProductVariant {
  /// Creates one inventory and pricing boundary.
  const AdminCreateProductVariant({
    required this.title,
    required this.inventoryQuantity,
    required this.manageInventory,
    required this.allowBackorder,
    required this.optionValues,
    required this.prices,
    this.sku,
  });

  /// Decodes the generated variant input.
  factory AdminCreateProductVariant.fromJson(Map<String, Object?> json) =>
      _$AdminCreateProductVariantFromJson(json);

  /// Whether sales may continue below available stock.
  final bool allowBackorder;

  /// Starting on-hand quantity when inventory is managed.
  @Validate(range: Range(min: 0), message: 'Enter a non-negative quantity')
  final int inventoryQuantity;

  /// Whether checkout enforces [inventoryQuantity].
  final bool manageInventory;

  /// Selected value keyed by the option title in this request.
  final Map<String, String> optionValues;

  /// One exact amount for every active storefront currency.
  final List<AdminCreateProductPrice> prices;

  /// Optional unique stock-keeping identifier.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? sku;

  /// Merchant-facing variant name.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter a variant name')
  @Validate(regex: r'.*\S.*', message: 'Enter a variant name')
  final String title;
}

/// Complete product graph accepted by the protected creation boundary.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminCreateProduct with _$AdminCreateProduct {
  /// Creates a product together with its options, variants, and prices.
  const AdminCreateProduct({
    required this.status,
    required this.title,
    required this.discountable,
    required this.options,
    required this.variants,
    required this.media,
    this.handle,
    this.subtitle,
    this.material,
    this.description,
  });

  /// Decodes the generated product input without handwritten JSON mapping.
  factory AdminCreateProduct.fromJson(Map<String, Object?> json) =>
      _$AdminCreateProductFromJson(json);

  /// Optional long-form product copy.
  @Validate(length: Length(max: 20000), message: 'Use at most 20000 characters')
  final String? description;

  /// Whether promotions may reduce this product's price.
  final bool discountable;

  /// Optional URL segment; the server derives one from [title] when empty.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  @Validate(
    regex: r'^$|^[a-z0-9]+(?:-[a-z0-9]+)*$',
    message: 'Use lowercase letters, numbers, and hyphens',
  )
  final String? handle;

  /// Optional merchant material.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? material;

  /// Ordered uploaded assets attached in the same product transaction.
  final List<AdminCreateProductMedia> media;

  /// Option axes created in the same transaction as the product.
  final List<AdminCreateProductOption> options;

  /// Publishing state chosen by the merchant.
  final AdminProductLifecycle status;

  /// Optional secondary merchant-facing product name.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? subtitle;

  /// Required product name shown to merchants and customers.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter a title')
  @Validate(regex: r'.*\S.*', message: 'Enter a title')
  final String title;

  /// Sellable variants created with complete option selections and prices.
  final List<AdminCreateProductVariant> variants;
}

/// Active storefront currencies required by the product creation form.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductCreateContext with _$AdminProductCreateContext {
  /// Creates an admin-only product setup response.
  const AdminProductCreateContext({required this.currencyCodes});

  /// Decodes the generated context response.
  factory AdminProductCreateContext.fromJson(Map<String, Object?> json) =>
      _$AdminProductCreateContextFromJson(json);

  /// Sorted distinct currencies backed by active selling regions.
  final List<String> currencyCodes;
}

/// Complete replacement of the general fields editable in this schema.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminUpdateProduct with _$AdminUpdateProduct {
  /// Creates a validated merchant product update.
  const AdminUpdateProduct({
    required this.status,
    required this.title,
    required this.handle,
    required this.discountable,
    this.subtitle,
    this.material,
    this.description,
  });

  /// Decodes the generated admin request without handwritten key mapping.
  factory AdminUpdateProduct.fromJson(Map<String, Object?> json) =>
      _$AdminUpdateProductFromJson(json);

  /// Optional long-form product copy; an empty value clears it.
  @Validate(length: Length(max: 20000), message: 'Use at most 20000 characters')
  final String? description;

  /// Whether promotions may reduce this product's price.
  final bool discountable;

  /// Unique, URL-safe storefront segment.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter a handle')
  @Validate(
    regex: r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
    message: 'Use lowercase letters, numbers, and hyphens',
  )
  final String handle;

  /// Optional merchant material; an empty value clears it.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? material;

  /// Publishing state selected by the merchant.
  final AdminProductLifecycle status;

  /// Optional secondary merchant-facing product name.
  @Validate(length: Length(max: 255), message: 'Use at most 255 characters')
  final String? subtitle;

  /// Required product name shown to merchants and customers.
  @Validate(length: Length(min: 1, max: 255), message: 'Enter a title')
  @Validate(regex: r'.*\S.*', message: 'Enter a title')
  final String title;
}

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
  final AdminProductLifecycle status;

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
    required this.discountable,
    this.description,
    this.subtitle,
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

  /// Whether promotions may reduce this product's price.
  final bool discountable;

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
  final AdminProductLifecycle status;

  /// Optional secondary merchant-facing product name.
  final String? subtitle;

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
