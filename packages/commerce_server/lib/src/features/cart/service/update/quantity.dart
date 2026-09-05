import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/sellable_variant.dart';
import 'package:dust_dart/db.dart';

/// Why an existing line quantity could not be replaced.
enum UpdateLineFailure {
  /// The line does not belong to this cart.
  noLine,

  /// The line's variant is no longer available in this cart's currency.
  unavailable,

  /// Current inventory cannot cover the requested quantity.
  outOfStock,
}

/// Replaces a cart line's quantity after rechecking current inventory.
Future<Result<UpdateLineFailure?, SqlxError>> updateLineQuantity(
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String cartId,
  required String lineId,
  required int quantity,
}) async {
  final foundCart = await reads.findCart(cartId);
  if (foundCart case Err(:final error)) return Err(error);
  final cart = (foundCart as Ok<CartRow?, SqlxError>).value;
  if (cart == null) return const Ok(UpdateLineFailure.noLine);

  final foundLine = await reads.findLineById(cartId, lineId);
  if (foundLine case Err(:final error)) return Err(error);
  final line = (foundLine as Ok<LineItemRow?, SqlxError>).value;
  if (line == null) return const Ok(UpdateLineFailure.noLine);

  final priced = await catalog.findVariant(line.variantId, cart.currencyCode);
  if (priced case Err(:final error)) return Err(error);
  final variant = (priced as Ok<SellableVariantRow?, SqlxError>).value;
  if (variant == null) return const Ok(UpdateLineFailure.unavailable);
  if (!assembleSellableVariant(variant).canFulfil(quantity)) {
    return const Ok(UpdateLineFailure.outOfStock);
  }

  final written = await writes.setLineQuantity(lineId, quantity, cartId);
  if (written case Err(:final error)) return Err(error);
  if ((written as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
    return const Ok(UpdateLineFailure.noLine);
  }
  return const Ok(null);
}
