import 'package:commerce_shared/src/customers/address.dart';
import 'package:commerce_shared/src/money.dart';
import 'package:commerce_shared/src/ordering/cart.dart';
import 'package:commerce_shared/src/ordering/line_item.dart';
import 'package:commerce_shared/src/region.dart';
import 'package:dust_dart/serde.dart';

part 'order.g.dart';

/// Where an order sits in its lifecycle.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum OrderStatus {
  /// Placed, not yet paid for.
  pending,

  /// Paid and done.
  completed,

  /// Called off before payment.
  cancelled,
}

/// Whether the money has moved.
@Derive([Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
enum PaymentStatus {
  /// Placed, nothing taken.
  awaiting,

  /// Funds taken.
  captured,

  /// Funds returned.
  refunded,
}

/// A cart, frozen at the moment it was placed.
///
/// Every amount here is stored, not derived. An order recomputed from today's
/// prices, tax rates, or catalogue would change what a customer was charged
/// months after they were charged it, which is the one thing an order exists
/// to prevent. The region is kept for the record, not to recalculate with.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class Order with _$Order {
  /// Creates an [Order] from already-frozen values.
  const Order({
    required this.id,
    required this.email,
    required this.region,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.shippingAddress,
    required this.billingAddress,
    required this.placedAt,
    this.customerId,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.awaiting,
  });

  /// Places [cart] as an order, freezing its lines and totals.
  ///
  /// Throws [ArgumentError] when the cart is empty or carries no email. Both
  /// are states a cart is allowed to be in and an order is not.
  factory Order.fromCart({
    required String id,
    required Cart cart,
    required Address shippingAddress,
    required DateTime placedAt,
    Address? billingAddress,
  }) {
    if (cart.isEmpty) {
      throw ArgumentError.value(cart, 'cart', 'an empty cart is not an order');
    }
    final email = cart.email;
    if (email == null || email.isEmpty) {
      throw ArgumentError.value(
        cart,
        'cart',
        'an order needs an email to reach the buyer on',
      );
    }
    return Order(
      id: id,
      email: email,
      customerId: cart.customerId,
      region: cart.region,
      items: List<LineItem>.unmodifiable(cart.items),
      subtotal: cart.subtotal,
      tax: cart.tax,
      total: cart.total,
      shippingAddress: shippingAddress,
      billingAddress: billingAddress ?? shippingAddress,
      placedAt: placedAt,
    );
  }

  /// Creates an [Order] from JSON.
  factory Order.fromJson(Map<String, Object?> json) => _$OrderFromJson(json);

  /// Where the invoice goes.
  final Address billingAddress;

  /// The account that placed this, when there was one.
  final String? customerId;

  /// Contact address for the buyer.
  final String email;

  /// Unique identifier.
  final String id;

  /// The lines as they stood at checkout.
  final List<LineItem> items;

  /// Whether the money has moved.
  final PaymentStatus paymentStatus;

  /// When this was placed.
  final DateTime placedAt;

  /// The territory it was sold under, kept for the record.
  final Region region;

  /// Where the goods go.
  final Address shippingAddress;

  /// Lifecycle state.
  final OrderStatus status;

  /// The frozen sum of the lines, before tax.
  final Money subtotal;

  /// The frozen tax.
  final Money tax;

  /// The frozen amount charged.
  final Money total;

  /// Whether the money has been taken.
  bool get isPaid => paymentStatus == PaymentStatus.captured;

  /// The number of units ordered.
  int get itemCount => items.fold(0, (count, item) => count + item.quantity);

  /// This order with payment captured, which completes it.
  ///
  /// Throws [StateError] when the order was cancelled: taking money for
  /// something called off is the failure this guard exists to prevent.
  Order captured() {
    if (status == OrderStatus.cancelled) {
      throw StateError('cannot capture payment on a cancelled order');
    }
    return copyWith(
      status: OrderStatus.completed,
      paymentStatus: PaymentStatus.captured,
    );
  }

  /// This order cancelled.
  ///
  /// Throws [StateError] once payment has been captured; that path is a
  /// refund, which is a different operation with different accounting.
  Order cancelled() {
    if (isPaid) {
      throw StateError('a paid order is refunded, not cancelled');
    }
    return copyWith(status: OrderStatus.cancelled);
  }
}
