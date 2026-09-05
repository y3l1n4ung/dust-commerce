import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// One order by id, or `Ok(null)` when there is none.
Future<Result<Order?, SqlxError>> loadOrder(
  CheckoutReadRepository reads,
  String orderId,
) async {
  final found = await reads.findOrder(orderId);
  if (found case Err(:final error)) return Err(error);

  final row = (found as Ok<OrderRow?, SqlxError>).value;
  if (row == null) return const Ok(null);

  final items = await reads.itemsOf(orderId);
  if (items case Err(:final error)) return Err(error);

  final addresses = await reads.addressesOf(orderId);
  if (addresses case Err(:final error)) return Err(error);

  return Ok(
    orderOf(
      row,
      (items as Ok<List<LineItemRow>, SqlxError>).value,
      (addresses as Ok<List<OrderAddressRow>, SqlxError>).value,
    ),
  );
}
