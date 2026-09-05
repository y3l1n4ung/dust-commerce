import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}/shipping-options` — what this cart may choose from.
Handler listShippingOptionsHandler(
  CartReadRepository reads,
  CartListRepository lists,
) {
  return (Request request) async {
    final cartId = pathParametersOf(request)['id'];
    if (cartId == null || cartId.isEmpty) {
      return badRequest('A cart id is required');
    }

    final result = await shippingOptionsFor(reads, lists, cartId);

    return switch (result) {
      Ok(value: final options?) => jsonResponse({
          'shipping_options': [
            for (final option in options) option.toJson(),
          ],
          'count': options.length,
        }),
      Ok() => notFound('Cart "$cartId"'),
      Err() => internalError(),
    };
  };
}
