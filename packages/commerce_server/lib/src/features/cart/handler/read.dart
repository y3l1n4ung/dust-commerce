import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// The cart id in the path, or a rejection naming what was missing.
Result<String, Rejection> cartIdOf(Request request) {
  final id = pathParametersOf(request)['id'];
  if (id == null || id.isEmpty) {
    return const Err(Rejection.badRequest('A cart id is required'));
  }
  return Ok(id);
}

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
  final id = cartIdOf(request);
  if (id case Err(:final error)) return Err(error);

  final state = await cartDeps(request);
  if (state case Err(:final error)) return Err(error);

  return cartViewOf(
    (state as Ok<CartDeps, Rejection>).value.reads,
    (id as Ok<String, Rejection>).value,
  );
}
