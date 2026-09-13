import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'model.g.dart';

/// Owned order facts required before any return item is accepted.
@Derive([FromRow()])
final class OrderReturnCandidate {
  /// Creates order eligibility facts directly from SQL.
  const OrderReturnCandidate(
      {required this.status, required this.paymentStatus});

  /// Payment must be captured before physical goods can be returned.
  @Sqlx(rename: 'payment_status')
  final String paymentStatus;

  /// Only completed orders have entered the post-purchase lifecycle.
  final String status;
}

/// Frozen line quantity and quantity already claimed by active returns.
@Derive([FromRow()])
final class OrderReturnItemCandidate {
  /// Creates item availability facts directly from SQL.
  const OrderReturnItemCandidate({
    required this.id,
    required this.quantity,
    required this.requestedQuantity,
  });

  /// Immutable order-item identifier.
  final String id;

  /// Quantity bought on the frozen order.
  final int quantity;

  /// Units already present in non-canceled return requests.
  @Sqlx(rename: 'requested_quantity')
  final int requestedQuantity;
}

/// Explicit Store response allowlist decoded directly from SQLx.
@Derive([FromRow(), Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class OrderReturnResponse with _$OrderReturnResponse {
  /// Creates a persisted return acknowledgement.
  const OrderReturnResponse({
    required this.id,
    required this.displayId,
    required this.orderId,
    required this.status,
    required this.itemQuantity,
    required this.requestedAt,
  });

  /// Short customer-facing request number.
  @Sqlx(rename: 'display_id')
  final int displayId;

  /// Stable opaque return identifier.
  final String id;

  /// Total requested units across every item.
  @Sqlx(rename: 'item_quantity')
  final int itemQuantity;

  /// Owned order associated with this request.
  @Sqlx(rename: 'order_id')
  final String orderId;

  /// Database-generated UTC request instant.
  @Sqlx(rename: 'requested_at')
  final DateTime requestedAt;

  /// Typed lifecycle decoded from the stored Medusa-compatible value.
  @SerDe(using: _OrderReturnStatusCodec())
  @Sqlx(tryFrom: _OrderReturnStatusSqlx())
  final OrderReturnStatus status;
}

final class _OrderReturnStatusCodec
    implements SerDeCodec<OrderReturnStatus, String> {
  const _OrderReturnStatusCodec();

  @override
  OrderReturnStatus deserialize(String value) => _status(value);

  @override
  String serialize(OrderReturnStatus value) => _statusName(value);
}

final class _OrderReturnStatusSqlx
    implements SqlxTryFrom<OrderReturnStatus, String> {
  const _OrderReturnStatusSqlx();

  @override
  OrderReturnStatus decode(String value) => _status(value);
}

OrderReturnStatus _status(String value) => switch (value) {
      'open' => OrderReturnStatus.open,
      'requested' => OrderReturnStatus.requested,
      'received' => OrderReturnStatus.received,
      'partially_received' => OrderReturnStatus.partiallyReceived,
      'canceled' => OrderReturnStatus.canceled,
      _ => throw ArgumentError.value(value, 'value', 'Unknown return status'),
    };

String _statusName(OrderReturnStatus value) => switch (value) {
      OrderReturnStatus.open => 'open',
      OrderReturnStatus.requested => 'requested',
      OrderReturnStatus.received => 'received',
      OrderReturnStatus.partiallyReceived => 'partially_received',
      OrderReturnStatus.canceled => 'canceled',
    };
