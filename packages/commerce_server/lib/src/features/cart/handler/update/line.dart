import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/handler/read.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<AddLineBody> _body =
    ValidatedExtractable(JsonExtractable<AddLineBody>(AddLineBody.fromJson));

/// `POST /carts/{id}/line-items` — add a variant to the cart.
///
/// The three outcomes are deliberately different statuses. A missing cart is a
/// 404 about the thing in the path; an unknown variant is a 422 about the
/// body; running out of stock is a 409, because somebody buying the last one
/// is an ordinary outcome of a shop rather than a malformed request.
Future<Result<CartView, Rejection>> addLineHandler(Request request) async {
  final id = cartIdOf(request);
  if (id case Err(:final error)) return Err(error);
  final cartId = (id as Ok<String, Rejection>).value;

  final decoded = await _body.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final body = (decoded as Ok<AddLineBody, Rejection>).value;

  final state = await cartDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CartDeps, Rejection>).value;

  final result = await addLine(
    deps.reads,
    deps.writes,
    deps.catalog,
    cartId: cartId,
    variantId: body.variantId,
    quantity: body.quantity,
    nextId: deps.clock.nextId,
  );

  return switch (result) {
    Ok(value: null) => await cartViewOf(deps.reads, cartId),
    Ok(value: AddLineFailure.noCart) =>
      Err(Rejection.notFound('Cart "$cartId"')),
    Ok(value: AddLineFailure.noVariant) => Err(
        Rejection.status(
          422,
          'Variant "${body.variantId}" is not on sale in this currency',
        ),
      ),
    Ok(value: AddLineFailure.outOfStock) =>
      Err(Rejection.conflict('Not enough stock for "${body.variantId}"')),
    Err() => const Err(Rejection.internal()),
  };
}
