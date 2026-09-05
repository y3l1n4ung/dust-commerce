import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Starts an empty cart, in [regionId] when one is named.
///
/// A storefront that has not asked for a region still needs a cart, so the
/// default is used rather than the request being refused. Naming a region
/// matters as soon as there is more than one: without it the cart's currency
/// depends on which region sorts first, which is not a decision anybody made.
///
/// Returns `Ok(null)` when the named region does not exist, or when the shop
/// has no regions at all.
Future<Result<Cart?, SqlxError>> createCart(
  CartCreateRepository writes, {
  required String id,
  required DateTime now,
  String? regionId,
  String? email,
  String? customerId,
}) async {
  final regions = regionId == null
      ? await writes.firstRegion()
      : await writes.regionById(regionId);
  if (regions case Err(:final error)) return Err(error);

  final region = (regions as Ok<RegionRow?, SqlxError>).value;
  if (region == null) return const Ok(null);

  final written = await writes.createCart(
    id,
    region.id,
    customerId,
    email,
    now.toUtc().toIso8601String(),
  );
  if (written case Err(:final error)) return Err(error);

  return Ok(
    Cart(
      id: id,
      region: Region(
        id: region.id,
        name: region.name,
        currencyCode: region.currencyCode,
        taxRate: region.taxRate,
        taxInclusive: region.taxInclusive != 0,
        countries:
            region.countries.split(',').where((it) => it.isNotEmpty).toList(),
      ),
      email: email,
      customerId: customerId,
      items: const [],
    ),
  );
}
