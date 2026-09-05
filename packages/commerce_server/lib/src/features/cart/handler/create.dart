import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// The body of a create, when one was sent.
///
/// A body is optional: `POST /carts` with nothing starts a cart in the default
/// region, which is what a storefront does before it knows where the customer
/// is.
const OptionalExtractable<CreateCartBody> _body = OptionalExtractable(
  ValidatedExtractable(
    JsonExtractable<CreateCartBody>(CreateCartBody.fromJson),
  ),
);

/// `POST /carts` — start an empty cart.
///
/// Answers with a [CartView] like every other cart endpoint, so a client has
/// one shape to decode whether it created the cart or fetched it.
Future<Result<CartView, Rejection>> createCartHandler(Request request) async {
  final decoded = await _body.extract(request);
  if (decoded case Err(:final error)) return Err(error);

  final body =
      switch ((decoded as Ok<Option<CreateCartBody>, Rejection>).value) {
    Some(value: final sent) => sent,
    None() => const CreateCartBody(),
  };

  final state = await cartDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CartDeps, Rejection>).value;

  final result = await createCart(
    deps.creates,
    id: deps.clock.nextId(),
    now: deps.clock.now(),
    regionId: body.regionId,
    email: body.email,
  );

  return switch (result) {
    Ok(value: final cart?) => Ok(CartView.of(cart)),
    Ok() when body.regionId != null =>
      Err(Rejection.status(422, 'Region "${body.regionId}" does not exist')),
    Ok() => const Err(
        Rejection.status(503, 'The shop has no region configured'),
      ),
    Err() => const Err(Rejection.internal()),
  };
}
