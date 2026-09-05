import 'dart:convert';

import 'package:commerce_server/src/features/cart/repository/repository.dart';
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
  CartRepository carts,
  CatalogRepository catalog, {
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
      carts,
      catalog,
      cartId: cartId,
      variantId: variantId,
      quantity: quantity,
      nextId: nextId,
    );

    return switch (result) {
      Ok(value: null) => await _reload(carts, cartId),
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

Future<Response> _reload(CartRepository carts, String cartId) async {
  final reloaded = await loadCart(carts, cartId);

  return switch (reloaded) {
    Ok(value: final cart?) => jsonResponse({
        ...cart.toJson(),
        'subtotal': cart.subtotal.toJson(),
        'tax': cart.tax.toJson(),
        'total': cart.total.toJson(),
        'item_count': cart.itemCount,
      }),
    Ok() => notFound('Cart "$cartId"'),
    Err() => internalError(),
  };
}
