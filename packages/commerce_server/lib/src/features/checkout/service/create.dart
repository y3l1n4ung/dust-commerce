import 'package:commerce_server/src/features/cart/model/cart.dart';
import 'package:commerce_server/src/features/cart/model/promotion.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_server/src/infra/option.dart';
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

  /// The cart belongs to another authenticated customer.
  wrongCustomer,
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
Future<Result<Result<OrderResponse, CheckoutFailure>, SqlxError>> placeOrder(
  CommerceDatabase database, {
  required String cartId,
  required String email,
  required Option<String> customerId,
  required Address shippingAddress,
  required Address billingAddress,
  required DateTime placedAt,
  required String Function() nextId,
}) async {
  return database.transaction((tx) async {
    final carts = CartReadRepository(tx);
    final orders = CheckoutCreateRepository(tx);
    final reads = CheckoutReadRepository(tx);

    final loaded = await loadCart(carts, cartId);
    if (loaded case Err(:final error)) return Err(error);

    final cartOption = (loaded as Ok<Option<CartResponse>, SqlxError>).value;
    if (cartOption case None()) {
      return const Ok(Err(CheckoutFailure.noCart));
    }
    final cart = (cartOption as Some<CartResponse>).value;
    if (cart.customerId case final owner? when customerId != Some(owner)) {
      return const Ok(Err(CheckoutFailure.wrongCustomer));
    }

    final previousId = await reads.orderIdForCart(cartId);
    if (previousId case Err(:final error)) return Err(error);
    final previous = optionOf(
      (previousId as Ok<String?, SqlxError>).value,
    );
    if (previous case Some(value: final orderId)) {
      final response = await reads.findOrder(orderId);
      if (response case Err(:final error)) return Err(error);
      final order = optionOf(
        (response as Ok<OrderResponse?, SqlxError>).value,
      );
      if (order case Some(value: final existing)) return Ok(Ok(existing));
      return Err(SqlxError.decode('Existing cart order could not be read'));
    }
    if (cart.isEmpty) return const Ok(Err(CheckoutFailure.emptyCart));

    for (final line in cart.items) {
      final taken = await orders.reserveStock(line.variantId, line.quantity);
      if (taken case Err(:final error)) return Err(error);
      if ((taken as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
        return const Ok(Err(CheckoutFailure.outOfStock));
      }
    }

    final orderId = nextId();
    final written = await orders.insertOrder(
      orderId,
      cartId,
      cart.region.id,
      customerId.match<String?>(
        some: (value) => value,
        none: () => cart.customerId,
      ),
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
        line.productHandle,
        line.thumbnail,
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
      final applied = optionOf(
        (promotion as Ok<AppliedPromotion?, SqlxError>).value,
      );
      if (applied case Some(value: final promotion)) {
        final counted = await orders.countRedemption(promotion.code);
        if (counted case Err(:final error)) return Err(error);
      }
    }

    final completed = await orders.completeCart(
      cartId,
      placedAt.toUtc().toIso8601String(),
    );
    if (completed case Err(:final error)) return Err(error);

    final emptied = await orders.clearCart(cartId);
    if (emptied case Err(:final error)) return Err(error);

    final response = await reads.findOrder(orderId);
    if (response case Err(:final error)) return Err(error);
    final created = optionOf(
      (response as Ok<OrderResponse?, SqlxError>).value,
    );
    return switch (created) {
      Some(value: final order) => Ok(Ok(order)),
      None() => Err(
          SqlxError.decode('The order was written but could not be read back'),
        ),
    };
  });
}
