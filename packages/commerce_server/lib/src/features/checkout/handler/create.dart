import 'dart:convert';

import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/features/checkout/validation.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `POST /checkout` — turn a cart into an order.
///
/// The request is validated with the generated validators on
/// [CheckoutRequest], so the rules a Flutter form shows are the same rules the
/// server enforces, from one definition.
Handler placeOrderHandler(
  CommerceDatabase database, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return (Request request) async {
    final CheckoutRequest input;
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is! Map<String, Object?>) {
        return badRequest('Expected a JSON object');
      }
      input = CheckoutRequest.fromJson(decoded);
    } on FormatException {
      return badRequest('Expected a JSON object');
    } on ArgumentError catch (error) {
      return unprocessable(error.message.toString());
    }

    final failures = validateCheckout(input);
    if (failures.isNotEmpty) {
      return jsonResponse(
        {
          'error': {
            'code': 'validation_failed',
            'message': 'The request is not valid',
            'fields': [
              for (final failure in failures)
                {'field': failure.field, 'message': failure.message},
            ],
          },
        },
        status: 422,
      );
    }

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
      Ok(value: (final order?, _)) => jsonResponse(order.toJson(), status: 201),
      Ok(value: (_, CheckoutFailure.noCart)) =>
        notFound('Cart "${input.cartId}"'),
      Ok(value: (_, CheckoutFailure.emptyCart)) =>
        unprocessable('An empty cart cannot be ordered'),
      Ok(value: (_, CheckoutFailure.outOfStock)) => errorResponse(
          409,
          code: 'out_of_stock',
          message: 'Something in this cart sold out before checkout',
        ),
      Ok() => internalError(),
      Err() => internalError(),
    };
  };
}
