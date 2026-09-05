import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// The delivery options a cart may choose from.
///
/// Scoped to the cart's region rather than taking a region from the caller: a
/// storefront that could ask for another region's options would show prices in
/// a currency the cart cannot total.
Future<Result<List<ShippingMethod>?, SqlxError>> shippingOptionsFor(
  CartReadRepository reads,
  CartListRepository lists,
  String cartId,
) async {
  final found = await reads.findCart(cartId);
  if (found case Err(:final error)) return Err(error);
  final cart = (found as Ok<CartRow?, SqlxError>).value;
  if (cart == null) return const Ok(null);

  final offered = await lists.shippingOptionsOf(cart.regionId);
  if (offered case Err(:final error)) return Err(error);

  return Ok([
    for (final row in (offered as Ok<List<ShippingOptionRow>, SqlxError>).value)
      ShippingMethod(
        optionId: row.id,
        name: row.name,
        amount: Money(amount: row.amount, currencyCode: row.currencyCode),
      ),
  ]);
}
