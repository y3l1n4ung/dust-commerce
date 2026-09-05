import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/sellable_variant.dart';
import 'package:commerce_server/src/infra/option.dart';
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
Future<Result<Option<UpdateLineFailure>, SqlxError>> updateLineQuantity(
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String cartId,
  required String lineId,
  required int quantity,
}) async {
  final foundCart = await reads.findCart(cartId);
  if (foundCart case Err(:final error)) return Err(error);
  final cartOption = optionOf(
    (foundCart as Ok<CartResponse?, SqlxError>).value,
  );
  if (cartOption case None()) {
    return const Ok(Some(UpdateLineFailure.noLine));
  }
  final cart = (cartOption as Some<CartResponse>).value;

  final foundLine = await reads.findLineById(cartId, lineId);
  if (foundLine case Err(:final error)) return Err(error);
  final lineOption = optionOf(
    (foundLine as Ok<LineItemResponse?, SqlxError>).value,
  );
  if (lineOption case None()) {
    return const Ok(Some(UpdateLineFailure.noLine));
  }
  final line = (lineOption as Some<LineItemResponse>).value;

  final priced = await catalog.findVariant(line.variantId, cart.currencyCode);
  if (priced case Err(:final error)) return Err(error);
  final variantOption = optionOf(
    (priced as Ok<SellableVariant?, SqlxError>).value,
  );
  if (variantOption case None()) {
    return const Ok(Some(UpdateLineFailure.unavailable));
  }
  final variant = (variantOption as Some<SellableVariant>).value;
  if (!variant.canFulfil(quantity)) {
    return const Ok(Some(UpdateLineFailure.outOfStock));
  }

  final written = await writes.setLineQuantity(lineId, quantity, cartId);
  if (written case Err(:final error)) return Err(error);
  if ((written as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
    return const Ok(Some(UpdateLineFailure.noLine));
  }
  return const Ok(None<UpdateLineFailure>());
}
