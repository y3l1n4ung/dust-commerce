import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}` — the cart and its totals.
Handler readCartHandler(CartReadRepository reads) {
  return (Request request) async {
    final id = pathParametersOf(request)['id'];
    if (id == null || id.isEmpty) return badRequest('A cart id is required');

    final result = await loadCart(reads, id);

    return switch (result) {
      Ok(value: final cart?) => jsonResponse(cartBody(cart)),
      Ok() => notFound('Cart "$id"'),
      Err() => internalError(),
    };
  };
}

/// The cart as a client sees it: the cart, plus every total the server worked
/// out.
///
/// One function so the endpoints cannot disagree about what a cart looks like.
/// The totals travel rather than being recomputed on the client — a storefront
/// that adds up its own lines will one day disagree with the receipt, and the
/// server's answer is the one the customer is charged.
Map<String, Object?> cartBody(Cart cart) => {
      ...cart.toJson(),
      'subtotal': cart.subtotal.toJson(),
      'shipping_total': cart.shippingTotal.toJson(),
      'discount_total': cart.discountTotal.toJson(),
      'tax': cart.tax.toJson(),
      'total': cart.total.toJson(),
      'item_count': cart.itemCount,
    };
