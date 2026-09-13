import 'package:dust_dart/serde.dart';

part 'admin_order_status.g.dart';

/// Merchant-visible order lifecycle values supported by this schema.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum AdminOrderStatus {
  /// Placed and still open.
  pending,

  /// Successfully paid and completed.
  completed,

  /// Called off before completion.
  cancelled,
}

/// Merchant-visible payment state frozen on the order.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum AdminOrderPaymentStatus {
  /// Payment has not yet been captured.
  awaiting,

  /// The complete order total was captured.
  captured,

  /// Captured funds were returned.
  refunded,
}

/// Merchant-visible fulfilment state supported before fulfilment operations.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum AdminOrderFulfillmentStatus {
  /// No fulfilment has been created for the order.
  notFulfilled,
}

/// Persistence lifecycle of the order's provider payment collection.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum AdminOrderPaymentRecordStatus {
  /// A provider attempt has not yet authorized funds.
  pending,

  /// Funds are authorized but not captured.
  authorized,

  /// Funds have been captured.
  captured,

  /// The provider attempt was cancelled.
  cancelled,

  /// The provider attempt failed.
  failed,
}

/// Codec used by direct server projections for order lifecycle values.
final class AdminOrderStatusCodec
    implements SerDeCodec<AdminOrderStatus, String> {
  /// Creates the stateless codec.
  const AdminOrderStatusCodec();

  @override
  AdminOrderStatus deserialize(String value) =>
      AdminOrderStatus.values.byName(value);

  @override
  String serialize(AdminOrderStatus value) => value.name;
}

/// Codec used by direct server projections for payment state.
final class AdminOrderPaymentStatusCodec
    implements SerDeCodec<AdminOrderPaymentStatus, String> {
  /// Creates the stateless codec.
  const AdminOrderPaymentStatusCodec();

  @override
  AdminOrderPaymentStatus deserialize(String value) =>
      AdminOrderPaymentStatus.values.byName(value);

  @override
  String serialize(AdminOrderPaymentStatus value) => value.name;
}

/// Codec used by direct server projections for provider payment state.
final class AdminOrderPaymentRecordStatusCodec
    implements SerDeCodec<AdminOrderPaymentRecordStatus, String> {
  /// Creates the stateless codec.
  const AdminOrderPaymentRecordStatusCodec();

  @override
  AdminOrderPaymentRecordStatus deserialize(String value) =>
      AdminOrderPaymentRecordStatus.values.byName(value);

  @override
  String serialize(AdminOrderPaymentRecordStatus value) => value.name;
}

/// Codec used by direct server projections for fulfilment state.
final class AdminOrderFulfillmentStatusCodec
    implements SerDeCodec<AdminOrderFulfillmentStatus, String> {
  /// Creates the stateless codec.
  const AdminOrderFulfillmentStatusCodec();

  @override
  AdminOrderFulfillmentStatus deserialize(String value) => switch (value) {
        'not_fulfilled' => AdminOrderFulfillmentStatus.notFulfilled,
        _ => throw ArgumentError.value(value, 'value', 'Unknown fulfillment'),
      };

  @override
  String serialize(AdminOrderFulfillmentStatus value) => switch (value) {
        AdminOrderFulfillmentStatus.notFulfilled => 'not_fulfilled',
      };
}

/// Nullable JSON codec for the optional provider payment record state.
final class AdminOptionalPaymentRecordStatusCodec
    implements SerDeCodec<Option<AdminOrderPaymentRecordStatus>, Object?> {
  /// Creates the stateless codec.
  const AdminOptionalPaymentRecordStatusCodec();

  @override
  Option<AdminOrderPaymentRecordStatus> deserialize(Object? json) =>
      switch (json) {
        null => const None(),
        final String value => Some(AdminOrderPaymentRecordStatus.values
            .firstWhere((status) => status.name == value)),
        _ => throw FormatException('Expected a payment status or null'),
      };

  @override
  Object? serialize(Option<AdminOrderPaymentRecordStatus> value) =>
      switch (value) {
        Some(:final value) => value.name,
        None() => null,
      };
}
