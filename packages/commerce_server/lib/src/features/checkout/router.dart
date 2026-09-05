import 'package:commerce_server/src/features/checkout/handler/handler.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_server/server.dart';

/// Checkout's routes, mounted by the application under a prefix.
Router checkoutRoutes(
  CommerceDatabase database,
  CheckoutRepository orders, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return Router()
    ..route(
      '/checkout',
      post(placeOrderHandler(database, nextId: nextId, now: now)),
    )
    ..route('/orders', get(listOrdersHandler(orders)))
    ..route('/orders/{id}', get(getOrderHandler(orders)));
}
