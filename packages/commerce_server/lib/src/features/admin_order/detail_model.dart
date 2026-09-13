import 'dart:convert';

import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin_order/detail_address_response.dart';
import 'package:commerce_server/src/features/admin_order/detail_item_response.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'detail_model.g.dart';
part 'detail_sqlx.dart';

/// Complete Admin response populated directly from one SQLx projection.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminOrderDetailResponse with _$AdminOrderDetailResponse {
  /// Creates the explicit merchant response without a domain-model conversion.
  const AdminOrderDetailResponse({
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

  /// Billing destination, absent only for legacy snapshots.
  @Sqlx(
    rename: 'billing_address_json',
    defaultValue: null,
    tryFrom: _AdminOrderAddressFromString(),
  )
  final AdminOrderAddressResponse? billingAddress;

  /// Database-generated order creation instant.
  @Sqlx(rename: 'created_at', tryFrom: _AdminOrderDateTimeFromString())
  final DateTime createdAt;

  /// Lowercase ISO 4217 currency for every amount.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// Human-readable customer identity with email fallback.
  @Sqlx(rename: 'customer_name')
  final String customerName;

  /// Frozen discount in minor units.
  @Sqlx(rename: 'discount_total')
  final int discountTotal;

  /// Short merchant-facing order number.
  @Sqlx(rename: 'display_id')
  final int displayId;

  /// Contact email frozen at checkout.
  final String email;

  /// Fulfilment state represented by the current schema.
  @SerDe(using: AdminOrderFulfillmentStatusCodec())
  @Sqlx(
    rename: 'fulfillment_status',
    tryFrom: _AdminOrderFulfillmentStatusFromString(),
  )
  final AdminOrderFulfillmentStatus fulfillmentStatus;

  /// Stable opaque order identifier.
  final String id;

  /// Frozen line-item snapshots in creation order.
  @Sqlx(rename: 'items_json', tryFrom: _AdminOrderItemsFromString())
  final List<AdminOrderItemResponse> items;

  /// Amount recorded by the provider adapter, when present.
  @Sqlx(rename: 'payment_amount')
  final int? paymentAmount;

  /// Provider capture instant, when funds moved.
  @Sqlx(
    rename: 'payment_captured_at',
    defaultValue: null,
    tryFrom: _AdminOrderDateTimeFromString(),
  )
  final DateTime? paymentCapturedAt;

  /// Provider record creation instant, when present.
  @Sqlx(
    rename: 'payment_created_at',
    defaultValue: null,
    tryFrom: _AdminOrderDateTimeFromString(),
  )
  final DateTime? paymentCreatedAt;

  /// Public payment adapter identifier, when present.
  @Sqlx(rename: 'payment_provider')
  final String? paymentProvider;

  /// Provider payment record lifecycle, when present.
  @SerDe(using: AdminOrderPaymentRecordStatusCodec())
  @Sqlx(
    rename: 'payment_record_status',
    defaultValue: null,
    tryFrom: _AdminOrderPaymentRecordStatusFromString(),
  )
  final AdminOrderPaymentRecordStatus? paymentRecordStatus;

  /// Order-level payment lifecycle.
  @SerDe(using: AdminOrderPaymentStatusCodec())
  @Sqlx(
    rename: 'payment_status',
    tryFrom: _AdminOrderPaymentStatusFromString(),
  )
  final AdminOrderPaymentStatus paymentStatus;

  /// Business placement instant.
  @Sqlx(rename: 'placed_at', tryFrom: _AdminOrderDateTimeFromString())
  final DateTime placedAt;

  /// Applied promotion code, when one was frozen.
  @Sqlx(rename: 'promotion_code')
  final String? promotionCode;

  /// Shipping destination, absent only for legacy snapshots.
  @Sqlx(
    rename: 'shipping_address_json',
    defaultValue: null,
    tryFrom: _AdminOrderAddressFromString(),
  )
  final AdminOrderAddressResponse? shippingAddress;

  /// Selected delivery label, when one was frozen.
  @Sqlx(rename: 'shipping_name')
  final String? shippingName;

  /// Frozen delivery amount in minor units.
  @Sqlx(rename: 'shipping_total')
  final int shippingTotal;

  /// Current order lifecycle.
  @SerDe(using: AdminOrderStatusCodec())
  @Sqlx(tryFrom: _AdminOrderStatusFromString())
  final AdminOrderStatus status;

  /// Frozen goods subtotal in minor units.
  final int subtotal;

  /// Frozen tax amount in minor units.
  final int tax;

  /// Frozen charged total in minor units.
  final int total;

  /// Database-generated last mutation instant.
  @Sqlx(rename: 'updated_at', tryFrom: _AdminOrderDateTimeFromString())
  final DateTime updatedAt;
}
