import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `POST /carts` — start an empty cart.
Handler createCartHandler(
  CartCreateRepository writes, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return (Request request) async {
    final result = await createCart(
      writes,
      id: nextId(),
      now: now(),
    );

    return switch (result) {
      Ok(value: final cart?) => jsonResponse(cart.toJson(), status: 201),
      Ok() => errorResponse(
          503,
          code: 'no_region',
          message: 'The shop has no region configured',
        ),
      Err() => internalError(),
    };
  };
}
