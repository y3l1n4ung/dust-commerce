import 'package:commerce_admin_shared/src/admin_option.dart';
import 'package:commerce_admin_shared/src/admin_order_address.dart';
import 'package:commerce_admin_shared/src/admin_order_item.dart';
import 'package:commerce_admin_shared/src/admin_order_status.dart';
import 'package:dust_dart/serde.dart';

part 'admin_order_detail.g.dart';

/// Complete read-only merchant view of one frozen order.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminOrderDetail with _$AdminOrderDetail {
  /// Creates the explicit Admin detail contract.
  const AdminOrderDetail({
    required this.id,
    required this.displayId,
    required this.email,
    required this.customerName,
    required this.currencyCode,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.shippingName,
    required this.promotionCode,
    required this.placedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.shippingAddress,
    required this.billingAddress,
    required this.paymentProvider,
    required this.paymentAmount,
    required this.paymentRecordStatus,
    required this.paymentCreatedAt,
    required this.paymentCapturedAt,
  });

  /// Decodes one generated Admin order response.
  factory AdminOrderDetail.fromJson(Map<String, Object?> json) =>
      _$AdminOrderDetailFromJson(json);

  /// Billing destination, absent only for legacy snapshots.
  @SerDe(using: AdminOptionalOrderAddressCodec())
  final Option<AdminOrderAddress> billingAddress;

  /// Database-generated order creation instant.
  final DateTime createdAt;

  /// Lowercase ISO 4217 currency for every amount.
  final String currencyCode;

  /// Human-readable customer identity with email fallback.
  final String customerName;

  /// Frozen discount in minor units.
  final int discountTotal;

  /// Short merchant-facing order number.
  final int displayId;

  /// Contact email frozen at checkout.
  final String email;

  /// Fulfilment state represented by the current schema.
  @SerDe(using: AdminOrderFulfillmentStatusCodec())
  final AdminOrderFulfillmentStatus fulfillmentStatus;

  /// Stable opaque order identifier.
  final String id;

  /// Frozen line-item snapshots in creation order.
  final List<AdminOrderItem> items;

  /// Amount recorded by the provider adapter, when present.
  @SerDe(using: AdminOptionalIntCodec())
  final Option<int> paymentAmount;

  /// Provider capture instant, when funds moved.
  @SerDe(using: AdminOptionalDateTimeCodec())
  final Option<DateTime> paymentCapturedAt;

  /// Provider record creation instant, when present.
  @SerDe(using: AdminOptionalDateTimeCodec())
  final Option<DateTime> paymentCreatedAt;

  /// Public payment adapter identifier, when present.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> paymentProvider;

  /// Provider payment record lifecycle, when present.
  @SerDe(using: AdminOptionalPaymentRecordStatusCodec())
  final Option<AdminOrderPaymentRecordStatus> paymentRecordStatus;

  /// Order-level payment lifecycle.
  @SerDe(using: AdminOrderPaymentStatusCodec())
  final AdminOrderPaymentStatus paymentStatus;

  /// Business placement instant.
  final DateTime placedAt;

  /// Applied promotion code, when one was frozen.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> promotionCode;

  /// Shipping destination, absent only for legacy snapshots.
  @SerDe(using: AdminOptionalOrderAddressCodec())
  final Option<AdminOrderAddress> shippingAddress;

  /// Selected delivery label, when one was frozen.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> shippingName;

  /// Frozen delivery amount in minor units.
  final int shippingTotal;

  /// Current order lifecycle.
  @SerDe(using: AdminOrderStatusCodec())
  final AdminOrderStatus status;

  /// Frozen goods subtotal in minor units.
  final int subtotal;

  /// Frozen tax amount in minor units.
  final int tax;

  /// Frozen charged total in minor units.
  final int total;

  /// Database-generated last mutation instant.
  final DateTime updatedAt;
}

/// Nullable JSON codec for one order address.
final class AdminOptionalOrderAddressCodec
    implements SerDeCodec<Option<AdminOrderAddress>, Object?> {
  /// Creates the stateless codec.
  const AdminOptionalOrderAddressCodec();

  @override
  Option<AdminOrderAddress> deserialize(Object? json) => switch (json) {
        null => const None(),
        final Map<String, Object?> value =>
          Some(AdminOrderAddress.fromJson(value)),
        _ => throw FormatException('Expected an address object or null'),
      };

  @override
  Object? serialize(Option<AdminOrderAddress> value) => switch (value) {
        Some(:final value) => value.toJson(),
        None() => null,
      };
}
