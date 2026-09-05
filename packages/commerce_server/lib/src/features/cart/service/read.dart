import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// The cart with [cartId], with its lines, or `Ok(null)` when there is none.
///
/// Two queries rather than one join. A join would repeat the cart and region
/// columns once per line, and an empty cart — which is most carts, most of the
/// time — would return no rows at all, making "no cart" and "empty cart"
/// indistinguishable.
Future<Result<Cart?, SqlxError>> loadCart(
  CartReadRepository reads,
  String cartId,
) async {
  final found = await reads.findCart(cartId);
  if (found case Err(:final error)) return Err(error);

  final row = (found as Ok<CartRow?, SqlxError>).value;
  if (row == null) return const Ok(null);

  final lines = await reads.linesOf(cartId);
  if (lines case Err(:final error)) return Err(error);

  final method = await reads.shippingMethodOf(cartId);
  if (method case Err(:final error)) return Err(error);
  final chosen = (method as Ok<ShippingMethodRow?, SqlxError>).value;

  final promotion = await reads.promotionOn(cartId);
  if (promotion case Err(:final error)) return Err(error);
  final applied = (promotion as Ok<CartPromotionRow?, SqlxError>).value;

  return Ok(
    Cart(
      id: row.id,
      region: regionOf(
        id: row.regionId,
        name: row.regionName,
        currencyCode: row.currencyCode,
        taxRate: row.taxRate,
        taxInclusive: row.taxInclusive,
        countries: row.countries,
      ),
      email: row.email,
      customerId: row.customerId,
      items: (lines as Ok<List<LineItemRow>, SqlxError>)
          .value
          .map(lineOf)
          .toList(growable: false),
      shippingMethod:
          chosen == null ? null : methodOf(chosen, row.currencyCode),
      discount: applied == null
          ? null
          : Money(amount: applied.amount, currencyCode: row.currencyCode),
    ),
  );
}
