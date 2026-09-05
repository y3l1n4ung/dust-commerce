import 'package:commerce_server/src/features/checkout/handler/handler.dart';
import 'package:dust_server/server.dart';

/// Checkout's routes.
Router checkoutRoutes() {
  return Router()
    ..route('/checkout', post(placeOrderHandler, status: 201))
    ..route('/orders', get(listOrdersHandler))
    ..route('/orders/{id}', get(readOrderHandler));
}
