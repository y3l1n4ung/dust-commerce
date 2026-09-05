import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// Decodes and validates the checkout body in one step.
///
/// JsonExtractable rejects a non-JSON content type with 415, malformed syntax
/// with 400, and a body it cannot build a CheckoutRequest from with 422 —
/// each with its own message. ValidatedExtractable then runs the generated
/// constraints, including the nested address, because the request marks it
/// `@Validate(nested: true)`.
///
/// All of that used to be thirty lines of hand-rolled decoding in this file.
const ValidatedExtractable<CheckoutRequest> _body = ValidatedExtractable(
  JsonExtractable<CheckoutRequest>(CheckoutRequest.fromJson),
);

/// `POST /checkout` — turn a cart into an order.
///
/// Returns the order rather than a Response: the router encodes an `Ok` and
/// turns an `Err(Rejection)` into the status the rejection names, so this
/// function says what happened and nothing about HTTP plumbing.
Endpoint<Result<Order, Rejection>> placeOrderEndpoint(
  CommerceDatabase database, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return (Request request) async {
    final decoded = await _body.extract(request);
    if (decoded case Err(:final error)) return Err(error);
    final input = (decoded as Ok<CheckoutRequest, Rejection>).value;

    final shipping = input.shippingAddress.toAddress();
    final result = await placeOrder(
      database,
      cartId: input.cartId,
      email: input.email,
      shippingAddress: shipping,
      billingAddress: input.billingAddress?.toAddress() ?? shipping,
      placedAt: now(),
      nextId: nextId,
    );

    return switch (result) {
      Ok(value: (final order?, _)) => Ok(order),
      Ok(value: (_, CheckoutFailure.noCart)) =>
        Err(Rejection.notFound('Cart "${input.cartId}"')),
      Ok(value: (_, CheckoutFailure.emptyCart)) => const Err(
          Rejection.status(422, 'An empty cart cannot be ordered'),
        ),
      Ok(value: (_, CheckoutFailure.outOfStock)) => const Err(
          Rejection.conflict('Something in this cart sold out before checkout'),
        ),
      Ok() => const Err(Rejection.internal()),
      Err() => const Err(Rejection.internal()),
    };
  };
}
