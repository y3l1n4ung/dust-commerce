import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Builds the domain [Region] a row describes.
Region regionOf({
  required String id,
  required String name,
  required String currencyCode,
  required int taxRate,
  required int taxInclusive,
  required String countries,
}) {
  return Region(
    id: id,
    name: name,
    currencyCode: currencyCode,
    taxRate: taxRate,
    taxInclusive: taxInclusive != 0,
    countries: countries.split(',').where((it) => it.isNotEmpty).toList(),
  );
}

/// Builds the domain [LineItem] a row describes.
LineItem lineOf(LineItemRow row) => LineItem(
      id: row.id,
      variantId: row.variantId,
      productId: row.productId,
      title: row.title,
      variantTitle: row.variantTitle,
      unitPrice: Money(
        amount: row.unitAmount,
        currencyCode: row.currencyCode,
      ),
      quantity: row.quantity,
    );

/// The cart with [cartId], with its lines, or `Ok(null)` when there is none.
///
/// Two queries rather than one join. A join would repeat the cart and region
/// columns once per line, and an empty cart — which is most carts, most of the
/// time — would return no rows at all, making "no cart" and "empty cart"
/// indistinguishable.
Future<Result<Cart?, SqlxError>> loadCart(
  CartRepository repository,
  String cartId,
) async {
  final found = await repository.findCart(cartId);
  if (found case Err(:final error)) return Err(error);

  final row = (found as Ok<CartRow?, SqlxError>).value;
  if (row == null) return const Ok(null);

  final lines = await repository.linesOf(cartId);
  if (lines case Err(:final error)) return Err(error);

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
    ),
  );
}
