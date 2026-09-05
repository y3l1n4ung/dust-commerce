import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/handler/read.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}/shipping-options` — what this cart may choose from.
Future<Result<ShippingOptionsView, Rejection>> listShippingOptionsHandler(
  Request request,
) async {
  final id = cartIdOf(request);
  if (id case Err(:final error)) return Err(error);
  final cartId = (id as Ok<String, Rejection>).value;

  final state = await cartDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CartDeps, Rejection>).value;

  final result = await shippingOptionsFor(deps.reads, deps.lists, cartId);

  return switch (result) {
    Ok(value: final options?) => Ok(ShippingOptionsView.of(options)),
    Ok() => Err(Rejection.notFound('Cart "$cartId"')),
    Err() => const Err(Rejection.internal()),
  };
}
