import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/product_json.dart' as json;
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

export 'product_list_model.dart';

part 'model.g.dart';

/// Direct credential query result kept outside every HTTP response.
@Derive([Eq(), FromRow()])
final class AdminPasswordCredential with _$AdminPasswordCredential {
  /// Creates the private credential projection.
  const AdminPasswordCredential({
    required this.authIdentityId,
    required this.passwordHash,
  });

  /// Provider-independent identity that owns this credential.
  @Sqlx(rename: 'auth_identity_id')
  final String authIdentityId;

  /// Argon2id PHC value; plaintext never reaches persistence.
  @Sqlx(rename: 'password_hash')
  final String passwordHash;
}

/// Public admin response selected directly from SQL without an ORM model.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminUserResponse with _$AdminUserResponse {
  /// Creates the public allowlist.
  const AdminUserResponse({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  /// Normalized operational email.
  final String email;

  /// Optional given name for display only.
  @Sqlx(rename: 'first_name')
  final String? firstName;

  /// Stable admin user identifier.
  final String id;

  /// Optional family name for display only.
  @Sqlx(rename: 'last_name')
  final String? lastName;
}

/// One active storefront currency selected directly for product creation.
@Derive([FromRow()])
final class AdminProductCurrencyResponse {
  /// Creates the private one-column query projection.
  const AdminProductCurrencyResponse({required this.currencyCode});

  /// Lowercase ISO 4217 code backed by at least one active region.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;
}

/// Complete product detail selected directly from one SQL row.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductDetailResponse with _$AdminProductDetailResponse {
  /// Creates the explicitly allowlisted merchant detail response.
  const AdminProductDetailResponse({
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
    this.productTypeId,
    this.collectionTitle,
    this.weight,
    this.length,
    this.width,
    this.height,
  });

  /// Public categories assigned to this product.
  @Sqlx(tryFrom: _AdminProductStringsSqlxJson())
  final List<String> categories;

  /// Optional curated collection label.
  @Sqlx(rename: 'collection_title')
  final String? collectionTitle;

  /// Optional long-form merchant description.
  final String? description;

  /// Whether promotions may reduce this product's price.
  @Sqlx(tryFrom: _AdminBoolFromInt())
  final bool discountable;

  /// Optional height in the store's configured unit.
  final int? height;

  /// Stable storefront route segment.
  final String handle;

  /// Stable product identifier.
  final String id;

  /// Ordered merchant media.
  @Sqlx(tryFrom: _AdminProductImagesSqlxJson())
  final List<AdminProductImage> images;

  /// Optional length in the store's configured unit.
  final int? length;

  /// Optional merchant material description.
  final String? material;

  /// Ordered selectable dimensions.
  @Sqlx(tryFrom: _AdminProductOptionsSqlxJson())
  final List<AdminProductOption> options;

  /// Optional ISO 3166-1 alpha-2 country code.
  @Sqlx(rename: 'origin_country')
  final String? originCountry;

  /// Optional merchant classification.
  @Sqlx(rename: 'product_type')
  final String? productType;

  /// Stable classification identifier used by Admin mutation contracts.
  @Sqlx(rename: 'product_type_id')
  final String? productTypeId;

  /// Merchant lifecycle state.
  @SerDe(using: AdminProductLifecycleCodec())
  @Sqlx(tryFrom: _AdminProductLifecycleSqlx())
  final AdminProductLifecycle status;

  /// Optional secondary merchant-facing product name.
  final String? subtitle;

  /// Public discovery tags assigned to this product.
  @Sqlx(tryFrom: _AdminProductStringsSqlxJson())
  final List<String> tags;

  /// Optional primary merchant image.
  final String? thumbnail;

  /// Merchant-facing product name.
  final String title;

  /// Inventory-bearing variants.
  @Sqlx(tryFrom: _AdminProductVariantsSqlxJson())
  final List<AdminProductVariant> variants;

  /// Optional weight in the store's configured unit.
  final int? weight;

  /// Optional width in the store's configured unit.
  final int? width;
}

final class _AdminProductImagesSqlxJson
    implements SqlxTryFrom<List<AdminProductImage>, String> {
  const _AdminProductImagesSqlxJson();

  @override
  List<AdminProductImage> decode(String value) =>
      const json.AdminProductImagesFromJson().decode(value);
}

final class _AdminProductOptionsSqlxJson
    implements SqlxTryFrom<List<AdminProductOption>, String> {
  const _AdminProductOptionsSqlxJson();

  @override
  List<AdminProductOption> decode(String value) =>
      const json.AdminProductOptionsFromJson().decode(value);
}

final class _AdminProductVariantsSqlxJson
    implements SqlxTryFrom<List<AdminProductVariant>, String> {
  const _AdminProductVariantsSqlxJson();

  @override
  List<AdminProductVariant> decode(String value) =>
      const json.AdminProductVariantsFromJson().decode(value);
}

final class _AdminProductStringsSqlxJson
    implements SqlxTryFrom<List<String>, String> {
  const _AdminProductStringsSqlxJson();

  @override
  List<String> decode(String value) =>
      const json.AdminProductStringsFromJson().decode(value);
}

final class _AdminProductLifecycleSqlx
    implements SqlxTryFrom<AdminProductLifecycle, String> {
  const _AdminProductLifecycleSqlx();

  @override
  AdminProductLifecycle decode(String value) =>
      AdminProductLifecycle.values.byName(value);
}

final class _AdminBoolFromInt implements SqlxTryFrom<bool, int> {
  const _AdminBoolFromInt();

  @override
  bool decode(int value) => value != 0;
}
