import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Why a line could not be added.
enum AddLineFailure {
  /// No cart with that id.
  noCart,

  /// The variant does not exist, or is not sold in the cart's currency.
  noVariant,

  /// The variant exists but cannot cover the quantity asked for.
  outOfStock,
}

/// Adds [quantity] of [variantId] to the cart, or says why it could not.
///
/// The price is read from the catalogue **here**, at the moment of adding, and
/// written into the line. Reading it again later would let a repricing rewrite
/// what a customer already agreed to.
///
/// Stock is checked before the write rather than trusted to a constraint,
/// because "somebody bought the last one" is an ordinary outcome of a shop and
/// deserves an answer a customer can read, not a failed insert.
///
/// Adding a variant the cart already holds raises that line's quantity instead
/// of appending a second one, keeping the earlier line's price.
Future<Result<AddLineFailure?, SqlxError>> addLine(
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String cartId,
  required String variantId,
  required int quantity,
  required String Function() nextId,
}) async {
  final found = await reads.findCart(cartId);
  if (found case Err(:final error)) return Err(error);
  final cart = (found as Ok<CartRow?, SqlxError>).value;
  if (cart == null) return const Ok(AddLineFailure.noCart);

  final priced = await catalog.findVariant(variantId, cart.currencyCode);
  if (priced case Err(:final error)) return Err(error);
  final variant = (priced as Ok<VariantRow?, SqlxError>).value;
  if (variant == null) return const Ok(AddLineFailure.noVariant);

  final existing = await reads.findLine(cartId, variantId);
  if (existing case Err(:final error)) return Err(error);
  final line = (existing as Ok<LineItemRow?, SqlxError>).value;

  final wanted = (line?.quantity ?? 0) + quantity;
  if (!assembleVariant(variant).canFulfil(wanted)) {
    return const Ok(AddLineFailure.outOfStock);
  }

  final written = line == null
      ? await writes.insertLine(
          nextId(),
          cartId,
          variant.id,
          variant.productId,
          variant.title,
          variant.title,
          variant.amount,
          variant.currencyCode,
          quantity,
        )
      : await writes.setLineQuantity(line.id, wanted);

  if (written case Err(:final error)) return Err(error);
  return const Ok(null);
}

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
