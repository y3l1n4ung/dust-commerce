import 'package:dust_dart/db.dart';

part 'model.g.dart';

/// One row of `payment_collections`.
@Derive([ToString(), Eq(), FromRow()])
final class PaymentRow with _$PaymentRow {
  /// Creates a [PaymentRow].
  const PaymentRow({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.capturedAt,
  });

  /// What is owed, in minor units.
  final int amount;

  /// When the money moved, ISO-8601.
  @Sqlx(rename: 'captured_at')
  final String? capturedAt;

  /// The currency it is owed in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The primary key.
  final String id;

  /// The order it belongs to.
  @Sqlx(rename: 'order_id')
  final String orderId;

  /// Who is taking the money. `manual` is the only one here.
  final String provider;

  /// `pending`, `authorized` or `captured`, as stored.
  final String status;
}
