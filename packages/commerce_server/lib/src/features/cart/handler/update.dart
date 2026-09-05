import 'package:commerce_server/src/features/cart/handler/read.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<AddLineBody> _addLine =
    ValidatedExtractable(JsonExtractable<AddLineBody>(AddLineBody.fromJson));

const ValidatedExtractable<ChooseShippingBody> _chooseShipping =
    ValidatedExtractable(
  JsonExtractable<ChooseShippingBody>(ChooseShippingBody.fromJson),
);

const ValidatedExtractable<ApplyPromotionBody> _applyPromotion =
    ValidatedExtractable(
  JsonExtractable<ApplyPromotionBody>(ApplyPromotionBody.fromJson),
);

/// `POST /carts/{id}/line-items` — add a variant to the cart.
///
/// The three outcomes are deliberately different statuses. A missing cart is a
/// 404 about the thing in the path; an unknown variant is a 422 about the
/// body; running out of stock is a 409, because somebody buying the last one
/// is an ordinary outcome of a shop rather than a malformed request.
Endpoint<Result<CartView, Rejection>> addLineEndpoint(
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String Function() nextId,
}) {
  return (Request request) async {
    final id = cartIdOf(request);
    if (id case Err(:final error)) return Err(error);
    final cartId = (id as Ok<String, Rejection>).value;

    final decoded = await _addLine.extract(request);
    if (decoded case Err(:final error)) return Err(error);
    final body = (decoded as Ok<AddLineBody, Rejection>).value;

    final result = await addLine(
      reads,
      writes,
      catalog,
      cartId: cartId,
      variantId: body.variantId,
      quantity: body.quantity,
      nextId: nextId,
    );

    return switch (result) {
      Ok(value: null) => await cartViewOf(reads, cartId),
      Ok(value: AddLineFailure.noCart) =>
        Err(Rejection.notFound('Cart "$cartId"')),
      Ok(value: AddLineFailure.noVariant) => Err(
          Rejection.status(
            422,
            'Variant "${body.variantId}" is not on sale in this currency',
          ),
        ),
      Ok(value: AddLineFailure.outOfStock) => Err(
          Rejection.conflict('Not enough stock for "${body.variantId}"'),
        ),
      Err() => const Err(Rejection.internal()),
    };
  };
}

/// `POST /carts/{id}/shipping-method` — choose how the goods travel.
Endpoint<Result<CartView, Rejection>> chooseShippingEndpoint(
  CartReadRepository reads,
  CartListRepository lists,
  CartUpdateRepository writes,
) {
  return (Request request) async {
    final id = cartIdOf(request);
    if (id case Err(:final error)) return Err(error);
    final cartId = (id as Ok<String, Rejection>).value;

    final decoded = await _chooseShipping.extract(request);
    if (decoded case Err(:final error)) return Err(error);
    final body = (decoded as Ok<ChooseShippingBody, Rejection>).value;

    final result = await chooseShipping(
      reads,
      lists,
      writes,
      cartId: cartId,
      optionId: body.optionId,
    );

    return switch (result) {
      Ok(value: null) => await cartViewOf(reads, cartId),
      Ok(value: ChooseShippingFailure.noCart) =>
        Err(Rejection.notFound('Cart "$cartId"')),
      Ok(value: ChooseShippingFailure.noOption) => Err(
          Rejection.status(
            422,
            'Shipping option "${body.optionId}" is not offered here',
          ),
        ),
      Err() => const Err(Rejection.internal()),
    };
  };
}

/// `POST /carts/{id}/promotions` — apply a code.
///
/// An unknown code and an expired one answer differently. Telling a customer
/// "that code does not exist" when it has merely finished is how a support
/// queue fills with people who typed it correctly.
Endpoint<Result<CartView, Rejection>> applyPromotionEndpoint(
  CartReadRepository reads,
  CartUpdateRepository writes, {
  required DateTime Function() now,
}) {
  return (Request request) async {
    final id = cartIdOf(request);
    if (id case Err(:final error)) return Err(error);
    final cartId = (id as Ok<String, Rejection>).value;

    final decoded = await _applyPromotion.extract(request);
    if (decoded case Err(:final error)) return Err(error);
    final body = (decoded as Ok<ApplyPromotionBody, Rejection>).value;

    final result = await applyPromotion(
      reads,
      writes,
      cartId: cartId,
      code: body.code,
      now: now(),
    );

    return switch (result) {
      Ok(value: null) => await cartViewOf(reads, cartId),
      Ok(value: ApplyPromotionFailure.noCart) =>
        Err(Rejection.notFound('Cart "$cartId"')),
      Ok(value: ApplyPromotionFailure.noPromotion) => Err(
          Rejection.status(
            422,
            'There is no promotion with the code "${body.code}"',
          ),
        ),
      Ok(value: ApplyPromotionFailure.notUsable) => Err(
          Rejection.status(422, 'The code "${body.code}" is not available'),
        ),
      Ok(value: ApplyPromotionFailure.wrongCurrency) => Err(
          Rejection.status(
            422,
            'The code "${body.code}" cannot be used in this currency',
          ),
        ),
      Err() => const Err(Rejection.internal()),
    };
  };
}

/// `DELETE /carts/{id}/promotions` — take the code off again.
Endpoint<Result<CartView, Rejection>> removePromotionEndpoint(
  CartReadRepository reads,
  CartUpdateRepository writes,
) {
  return (Request request) async {
    final id = cartIdOf(request);
    if (id case Err(:final error)) return Err(error);
    final cartId = (id as Ok<String, Rejection>).value;

    final result = await removePromotion(reads, writes, cartId);

    return switch (result) {
      Ok(value: true) => await cartViewOf(reads, cartId),
      Ok() => Err(Rejection.notFound('Cart "$cartId"')),
      Err() => const Err(Rejection.internal()),
    };
  };
}
