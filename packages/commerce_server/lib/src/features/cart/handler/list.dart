import 'package:commerce_server/src/features/cart/handler/read.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /carts/{id}/shipping-options` — what this cart may choose from.
Endpoint<Result<ShippingOptionsView, Rejection>> listShippingOptionsEndpoint(
  CartReadRepository reads,
  CartListRepository lists,
) {
  return (Request request) async {
    final id = cartIdOf(request);
    if (id case Err(:final error)) return Err(error);
    final cartId = (id as Ok<String, Rejection>).value;

    final result = await shippingOptionsFor(reads, lists, cartId);

    return switch (result) {
      Ok(value: final options?) => Ok(ShippingOptionsView.of(options)),
      Ok() => Err(Rejection.notFound('Cart "$cartId"')),
      Err() => const Err(Rejection.internal()),
    };
  };
}
