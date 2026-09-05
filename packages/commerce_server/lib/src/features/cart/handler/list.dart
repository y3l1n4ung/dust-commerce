import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/extractor.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}/shipping-options` — what this cart may choose from.
Future<Result<ShippingOptionsView, Rejection>> listShippingOptionsHandler(
  Request request,
) async {
  final access = await request.extract(const Extension<CartAccess>());
  final cartId = access.cart.id;

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
