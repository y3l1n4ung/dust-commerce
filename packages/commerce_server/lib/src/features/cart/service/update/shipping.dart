import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Why a delivery method could not be chosen.
enum ChooseShippingFailure {
  /// No cart with that id.
  noCart,

  /// The option does not exist, or belongs to another region.
  noOption,
}

/// Chooses [optionId] as the cart's delivery method.
///
/// The option is looked up scoped to the cart's own region, so one belonging
/// to another region cannot be chosen — the query refuses it rather than the
/// handler remembering to.
///
/// The price and name are snapshotted onto the cart, like a line item's price.
/// A shipping option repriced afterwards must not change what this cart was
/// quoted.
Future<Result<ChooseShippingFailure?, SqlxError>> chooseShipping(
  CartReadRepository reads,
  CartListRepository lists,
  CartUpdateRepository writes, {
  required String cartId,
  required String optionId,
}) async {
  final found = await reads.findCart(cartId);
  if (found case Err(:final error)) return Err(error);
  final cart = (found as Ok<CartRow?, SqlxError>).value;
  if (cart == null) return const Ok(ChooseShippingFailure.noCart);

  final offered = await lists.shippingOptionFor(optionId, cart.regionId);
  if (offered case Err(:final error)) return Err(error);
  final option = (offered as Ok<ShippingOptionRow?, SqlxError>).value;
  if (option == null) return const Ok(ChooseShippingFailure.noOption);

  final written = await writes.setShippingMethod(
    cartId,
    option.id,
    option.name,
    option.amount,
  );
  if (written case Err(:final error)) return Err(error);

  return const Ok(null);
}
