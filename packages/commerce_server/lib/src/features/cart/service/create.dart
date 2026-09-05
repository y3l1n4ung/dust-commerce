import 'package:commerce_server/src/features/cart/model/cart.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:dust_dart/db.dart';

/// Starts an empty cart, in [regionId] when one is named.
///
/// A storefront that has not asked for a region still needs a cart, so the
/// default is used rather than the request being refused. Naming a region
/// matters as soon as there is more than one: without it the cart's currency
/// depends on which region sorts first, which is not a decision anybody made.
///
/// Returns [None] when the named region does not exist, or when the shop has no
/// regions at all.
Future<Result<Option<CartResponse>, SqlxError>> createCart(
  CartCreateRepository writes, {
  required String id,
  String? regionId,
  String? email,
  String? customerId,
}) async {
  final regions = regionId == null
      ? await writes.firstRegion()
      : await writes.regionById(regionId);
  if (regions case Err(:final error)) return Err(error);

  final region = optionOf(
    (regions as Ok<RegionResponse?, SqlxError>).value,
  );
  if (region case None()) return const Ok(None<CartResponse>());
  final selected = (region as Some<RegionResponse>).value;

  final written = await writes.createCart(
    id,
    selected.id,
    customerId,
    email,
  );
  if (written case Err(:final error)) return Err(error);

  return Ok(
    Some<CartResponse>(CartResponse(
      id: id,
      region: selected,
      email: email,
      customerId: customerId,
      items: const [],
    )),
  );
}
