import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Starts an empty cart in the default region.
///
/// A storefront that has not asked for a region still needs a cart, so one is
/// chosen rather than the request being refused. Returns `Ok(null)` when no
/// region exists at all, which is a misconfigured shop rather than a bad
/// request.
Future<Result<Cart?, SqlxError>> createCart(
  CartCreateRepository writes, {
  required String id,
  required DateTime now,
  String? email,
  String? customerId,
}) async {
  final regions = await writes.firstRegion();
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
