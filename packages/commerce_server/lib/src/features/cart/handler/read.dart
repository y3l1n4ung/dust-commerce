import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}` — the cart and its totals.
Handler readCartHandler(CartReadRepository reads) {
  return (Request request) async {
    final id = pathParametersOf(request)['id'];
    if (id == null || id.isEmpty) return badRequest('A cart id is required');

    final result = await loadCart(reads, id);

    return switch (result) {
      Ok(value: final cart?) => jsonResponse({
          ...cart.toJson(),
          'subtotal': cart.subtotal.toJson(),
          'tax': cart.tax.toJson(),
          'total': cart.total.toJson(),
          'item_count': cart.itemCount,
        }),
      Ok() => notFound('Cart "$id"'),
      Err() => internalError(),
    };
  };
}
