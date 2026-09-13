import 'package:commerce_admin_shared/src/admin_option.dart';
import 'package:dust_dart/serde.dart';

part 'admin_order_item.g.dart';

/// One immutable line snapshot shown in the merchant order detail.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminOrderItem with _$AdminOrderItem {
  /// Creates a safe line-item response detached from mutable catalog data.
  const AdminOrderItem({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productHandle,
    required this.thumbnail,
    required this.title,
    required this.variantTitle,
    required this.unitAmount,
    required this.currencyCode,
    required this.quantity,
    required this.createdAt,
  });

  /// Decodes one generated Admin line response.
  factory AdminOrderItem.fromJson(Map<String, Object?> json) =>
      _$AdminOrderItemFromJson(json);

  /// Database-generated snapshot creation instant.
  final DateTime createdAt;

  /// Lowercase ISO 4217 currency for [unitAmount].
  final String currencyCode;

  /// Stable line identifier.
  final String id;

  /// Product route handle frozen at checkout.
  final String productHandle;

  /// Product identifier frozen at checkout.
  final String productId;

  /// Number of units purchased.
  final int quantity;

  /// Optional product image frozen at checkout.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> thumbnail;

  /// Product title frozen at checkout.
  final String title;

  /// Unit amount in the currency's minor unit.
  final int unitAmount;

  /// Catalog variant identifier frozen at checkout.
  final String variantId;

  /// Optional variant label frozen at checkout.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> variantTitle;
}
