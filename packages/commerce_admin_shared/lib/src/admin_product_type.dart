import 'package:dust_dart/serde.dart';

part 'admin_product_type.g.dart';

/// One reusable product classification visible to merchant clients.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductType with _$AdminProductType {
  /// Creates one explicit Admin API product-type allowlist.
  const AdminProductType({
    required this.id,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Decodes one generated product-type response.
  factory AdminProductType.fromJson(Map<String, Object?> json) =>
      _$AdminProductTypeFromJson(json);

  /// Database-generated creation instant.
  final DateTime createdAt;

  /// Stable classification identifier used by product filters.
  final String id;

  /// Database-generated last-modified instant.
  final DateTime updatedAt;

  /// Merchant-facing classification label.
  final String value;
}

/// One bounded Admin product-type page.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminProductTypeList with _$AdminProductTypeList {
  /// Creates generated-client paging metadata and explicit rows.
  const AdminProductTypeList({
    required this.productTypes,
    required this.count,
    required this.limit,
    required this.offset,
  });

  /// Decodes one generated Admin API response.
  factory AdminProductTypeList.fromJson(Map<String, Object?> json) =>
      _$AdminProductTypeListFromJson(json);

  /// Total active rows matching the query.
  final int count;

  /// Maximum requested page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Direct allowlisted product-type rows.
  final List<AdminProductType> productTypes;
}
