import 'package:commerce_server/src/features/checkout/deps.dart';
import 'package:commerce_server/src/features/checkout/handler/read.dart';
import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

/// `GET /orders` — the orders placed by one email address.
Future<Result<OrderListView, Rejection>> listOrdersHandler(
  Request request,
) async {
  final email = emailOf(request);
  if (email case Err(:final error)) return Err(error);
  final asked = (email as Ok<String, Rejection>).value;

  final state = await checkoutDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CheckoutDeps, Rejection>).value;

  final found = await deps.lists.ordersFor(asked);
  if (found case Err()) return const Err(Rejection.internal());

  final orders = <Order>[];
  for (final row in (found as Ok<List<OrderRow>, SqlxError>).value) {
    final loaded = await loadOrder(deps.reads, row.id);
    if (loaded case Err()) return const Err(Rejection.internal());
    final order = (loaded as Ok<Order?, SqlxError>).value;
    if (order != null) orders.add(order);
  }

  return Ok(OrderListView.of(orders));
}
