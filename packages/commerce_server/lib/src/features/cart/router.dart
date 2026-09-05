import 'package:commerce_server/src/features/cart/handler/handler.dart';
import 'package:dust_server/server.dart';

/// The cart's routes.
///
/// Handlers are named, not built: their dependencies arrive as state, so this
/// file says only which path serves which function.
Router cartRoutes() {
  return Router()
    ..route('/carts', post(createCartHandler, status: 201))
    ..route('/carts/{id}', get(readCartHandler))
    ..route('/carts/{id}/line-items', post(addLineHandler))
    ..route('/carts/{id}/shipping-options', get(listShippingOptionsHandler))
    ..route('/carts/{id}/shipping-method', post(chooseShippingHandler))
    ..route(
      // Chained, not cascaded: MethodRouter is immutable, so `..delete(...)`
      // would build a router and throw it away, leaving DELETE a 405.
      '/carts/{id}/promotions',
      post(applyPromotionHandler).delete(removePromotionHandler),
    );
}
