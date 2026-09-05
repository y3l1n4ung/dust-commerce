import 'dart:convert';

import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/handler/read.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `POST /carts/{id}/line-items` — add a variant to the cart.
///
/// The four outcomes are deliberately different statuses. A missing cart is a
/// 404 about the thing in the path; a variant that does not exist is a 422
/// about the body; and running out of stock is a 409, because "somebody bought
/// the last one" is an ordinary outcome of a shop rather than a malformed
/// request. A client that shows all three the same way is losing information
/// the server took care to distinguish.
Handler addLineHandler(
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String Function() nextId,
}) {
  return (Request request) async {
    final cartId = pathParametersOf(request)['id'];
    if (cartId == null || cartId.isEmpty) {
      return badRequest('A cart id is required');
    }

    final Map<String, Object?> body;
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is! Map<String, Object?>) {
        return badRequest('Expected a JSON object');
      }
      body = decoded;
    } on FormatException {
      return badRequest('Expected a JSON object');
    }

    final variantId = body['variant_id'];
    if (variantId is! String || variantId.isEmpty) {
      return unprocessable('variant_id is required');
    }

    final quantity = body['quantity'] ?? 1;
    if (quantity is! int || quantity < 1) {
      return unprocessable('quantity must be a whole number of at least one');
    }

    final result = await addLine(
      reads,
      writes,
      catalog,
      cartId: cartId,
      variantId: variantId,
      quantity: quantity,
      nextId: nextId,
    );

    return switch (result) {
      Ok(value: null) => await _reload(reads, cartId),
      Ok(value: AddLineFailure.noCart) => notFound('Cart "$cartId"'),
      Ok(value: AddLineFailure.noVariant) => unprocessable(
          'Variant "$variantId" is not on sale in this cart\'s currency',
        ),
      Ok(value: AddLineFailure.outOfStock) => errorResponse(
          409,
          code: 'out_of_stock',
          message: 'Not enough stock for variant "$variantId"',
        ),
      Err() => internalError(),
    };
  };
}

Future<Response> _reload(CartReadRepository reads, String cartId) async {
  final reloaded = await loadCart(reads, cartId);

  return switch (reloaded) {
    Ok(value: final cart?) => jsonResponse(cartBody(cart)),
    Ok() => notFound('Cart "$cartId"'),
    Err() => internalError(),
  };
}

/// `POST /carts/{id}/shipping-method` — choose how the goods travel.
///
/// A 422 rather than a 404 for an unknown option: the cart in the path exists,
/// it is the body that names something this region does not offer.
Handler chooseShippingHandler(
  CartReadRepository reads,
  CartListRepository lists,
  CartUpdateRepository writes,
) {
  return (Request request) async {
    final cartId = pathParametersOf(request)['id'];
    if (cartId == null || cartId.isEmpty) {
      return badRequest('A cart id is required');
    }

    final Map<String, Object?> body;
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is! Map<String, Object?>) {
        return badRequest('Expected a JSON object');
      }
      body = decoded;
    } on FormatException {
      return badRequest('Expected a JSON object');
    }

    final optionId = body['option_id'];
    if (optionId is! String || optionId.isEmpty) {
      return unprocessable('option_id is required');
    }

    final result = await chooseShipping(
      reads,
      lists,
      writes,
      cartId: cartId,
      optionId: optionId,
    );

    return switch (result) {
      Ok(value: null) => await _reload(reads, cartId),
      Ok(value: ChooseShippingFailure.noCart) => notFound('Cart "$cartId"'),
      Ok(value: ChooseShippingFailure.noOption) => unprocessable(
          'Shipping option "$optionId" is not offered in this region',
        ),
      Err() => internalError(),
    };
  };
}
