import 'package:commerce_server/src/features/cart/model/promotion.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Why a checkout could not be completed.
enum CheckoutFailure {
  /// No cart with that id.
  noCart,

  /// The cart holds nothing to order.
  emptyCart,

  /// Somebody took the last one between adding it and paying for it.
  outOfStock,
}

/// Turns a cart into an order, or says why it could not.
///
/// Everything happens in one transaction, and the **order of the writes is the
/// design**. Stock is taken first, so a sold-out line fails before an order
/// exists. Write the order first and a failure leaves a paid order that cannot
/// be shipped.
///
/// Stock is taken with a conditional UPDATE rather than a read followed by a
/// write. Two checkouts racing for the last unit both read "one left"; only the
/// write can decide between them, and a zero row count is how the loser finds
/// out.
///
/// The cart is emptied last. Its lines are copied onto the order first, so the
/// order does not reference rows that are about to be deleted.
Future<Result<(Order?, CheckoutFailure?), SqlxError>> placeOrder(
  CommerceDatabase database, {
  required String cartId,
  required String email,
  required Address shippingAddress,
  required Address billingAddress,
  required DateTime placedAt,
  required String Function() nextId,
}) async {
  return database.transaction((tx) async {
    final carts = CartReadRepository(tx);
    final orders = CheckoutCreateRepository(tx);

    final loaded = await loadCart(carts, cartId);
    if (loaded case Err(:final error)) return Err(error);

    final cart = (loaded as Ok<Cart?, SqlxError>).value;
    if (cart == null) return const Ok((null, CheckoutFailure.noCart));
    if (cart.isEmpty) return const Ok((null, CheckoutFailure.emptyCart));

    for (final line in cart.items) {
      final taken = await orders.reserveStock(line.variantId, line.quantity);
      if (taken case Err(:final error)) return Err(error);
      if ((taken as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
        return const Ok((null, CheckoutFailure.outOfStock));
      }
    }

    final orderId = nextId();
    final written = await orders.insertOrder(
      orderId,
      cart.region.id,
      cart.customerId,
      email,
      cart.region.currencyCode,
      cart.subtotal.amount,
      cart.shippingTotal.amount,
      cart.discountTotal.amount,
      cart.tax.amount,
      cart.total.amount,
      cart.shippingMethod?.optionId,
      cart.shippingMethod?.name,
      placedAt.toUtc().toIso8601String(),
    );
    if (written case Err(:final error)) return Err(error);

    for (final line in cart.items) {
      final copied = await orders.insertOrderItem(
        nextId(),
        orderId,
        line.variantId,
        line.productId,
        line.title,
        line.variantTitle,
        line.unitPrice.amount,
        line.unitPrice.currencyCode,
        line.quantity,
      );
      if (copied case Err(:final error)) return Err(error);
    }

    for (final (kind, address) in [
      ('shipping', shippingAddress),
      ('billing', billingAddress),
    ]) {
      final recorded = await orders.insertOrderAddress(
        orderId,
        kind,
        address.firstName,
        address.lastName,
        address.line1,
        address.line2,
        address.city,
        address.province,
        address.postalCode,
        address.countryCode,
        address.phone,
      );
      if (recorded case Err(:final error)) return Err(error);
    }

    // Counted before the cart is emptied, and inside the same transaction, so
    // a promotion cannot be redeemed by an order that then fails to write.
    if (cart.discount != null && !cart.discount!.isZero) {
      final promotion = await carts.promotionOn(cartId);
      if (promotion case Err(:final error)) return Err(error);
      final applied = (promotion as Ok<CartPromotionRow?, SqlxError>).value;
      if (applied != null) {
        final counted = await orders.countRedemption(applied.code);
        if (counted case Err(:final error)) return Err(error);
      }
    }

    final emptied = await orders.clearCart(cartId);
    if (emptied case Err(:final error)) return Err(error);

    return Ok((
      Order(
        id: orderId,
        email: email,
        customerId: cart.customerId,
        region: cart.region,
        items: cart.items,
        subtotal: cart.subtotal,
        shippingTotal: cart.shippingTotal,
        discountTotal: cart.discountTotal,
        shippingMethod: cart.shippingMethod,
        tax: cart.tax,
        total: cart.total,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        placedAt: placedAt,
      ),
      null,
    ));
  });
}
