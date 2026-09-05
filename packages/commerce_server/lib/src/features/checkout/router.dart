import 'package:commerce_server/src/features/checkout/handler/handler.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_server/server.dart';

/// Checkout's routes, mounted by the application under a prefix.
Router checkoutRoutes(
  CommerceDatabase database,
  CheckoutReadRepository reads,
  CheckoutListRepository lists, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return Router()
    ..route(
      '/checkout',
      post(placeOrderEndpoint(database, nextId: nextId, now: now), status: 201),
    )
    ..route('/orders', get(listOrdersEndpoint(lists, reads)))
    ..route('/orders/{id}', get(readOrderEndpoint(reads)));
}
