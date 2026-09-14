part of 'order.dart';

Order _orderFromCart({
  required String id,
  required int displayId,
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
    displayId: displayId,
    email: email,
    customerId: cart.customerId,
    region: cart.region,
    items: List<OrderLineItem>.unmodifiable(
      cart.items.map(OrderLineItem.fromCartLine),
    ),
    subtotal: cart.subtotal,
    shippingTotal: cart.shippingTotal,
    discountTotal: cart.discountTotal,
    shippingMethod: cart.shippingMethod,
    tax: cart.tax,
    total: cart.total,
    shippingAddress: shippingAddress,
    billingAddress: billingAddress ?? shippingAddress,
    placedAt: placedAt,
  );
}

/// Totals and lifecycle transitions derived from a frozen order.
extension OrderValues on Order {
  /// Whether the money has been taken.
  bool get isPaid => paymentStatus == PaymentStatus.captured;

  /// The number of units ordered.
  int get itemCount => items.fold(0, (count, item) => count + item.quantity);

  /// This order with payment captured while its lifecycle remains open.
  ///
  /// Throws [StateError] when the order was canceled: taking money for
  /// something called off is the failure this guard exists to prevent.
  Order captured() {
    if (status == OrderStatus.canceled) {
      throw StateError('cannot capture payment on a canceled order');
    }
    return copyWith(paymentStatus: PaymentStatus.captured);
  }

  /// This order canceled.
  ///
  /// Throws [StateError] once payment has been captured; that path is a
  /// refund, which is a different operation with different accounting.
  Order canceled() {
    if (isPaid) {
      throw StateError('a paid order is refunded, not canceled');
    }
    return copyWith(status: OrderStatus.canceled);
  }
}
