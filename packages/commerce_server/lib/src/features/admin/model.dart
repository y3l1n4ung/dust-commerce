import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

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

/// One product-list response populated directly from its SQL projection.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductResponse with _$AdminProductResponse {
  /// Creates an explicitly allowlisted merchant product row.
  const AdminProductResponse({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.collectionTitle,
    required this.salesChannels,
    required this.variantCount,
    required this.status,
  });

  /// Collection label, empty when no collection is attached.
  @Sqlx(rename: 'collection_title')
  final String collectionTitle;

  /// Stable product identifier.
  final String id;

  /// Sales-channel summary; empty until channel management is implemented.
  @Sqlx(rename: 'sales_channels')
  final String salesChannels;

  /// Merchant lifecycle state.
  final String status;

  /// Primary product image URL, or an empty value.
  final String thumbnail;

  /// Merchant-facing product name.
  final String title;

  /// Number of active variants.
  @Sqlx(rename: 'variant_count')
  final int variantCount;
}

/// Product rows plus their bounded-list metadata.
@Derive([Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductListResponse with _$AdminProductListResponse {
  /// Creates a merchant product page.
  const AdminProductListResponse({
    required this.products,
    required this.count,
    required this.limit,
    required this.offset,
  });

  /// Total rows matching the query.
  final int count;

  /// Maximum requested page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Explicit product summaries.
  final List<AdminProductResponse> products;
}
