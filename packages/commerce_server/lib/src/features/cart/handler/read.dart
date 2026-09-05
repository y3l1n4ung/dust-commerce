import 'package:commerce_server/src/features/cart/extractor.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// Loads a cart as the view a client sees, or says why it could not.
///
/// Shared by every endpoint that answers with a cart, so adding a total to
/// [CartView] reaches all of them without any being edited.
Future<Result<CartView, Rejection>> cartViewOf(
  CartReadRepository reads,
  String cartId,
) async {
  final loaded = await loadCart(reads, cartId);

  return switch (loaded) {
    Ok(value: final cart?) => Ok(CartView.of(cart)),
    Ok() => Err(Rejection.notFound('Cart "$cartId"')),
    Err() => const Err(Rejection.internal()),
  };
}

/// `GET /carts/{id}` — the cart and its totals.
Future<Result<CartView, Rejection>> readCartHandler(Request request) async {
  final access = await request.extract(const Extension<CartAccess>());
  return Ok(CartView.of(access.cart));
}
