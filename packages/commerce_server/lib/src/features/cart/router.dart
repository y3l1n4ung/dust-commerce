import 'package:commerce_server/src/features/cart/handler/handler.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_server/server.dart';

/// The cart's routes, mounted by the application under a prefix.
///
/// Every endpoint returns a typed value; the router encodes it and turns a
/// `Rejection` into the status it names, so no handler builds a `Response`.
Router cartRoutes(
  CartCreateRepository creates,
  CartReadRepository reads,
  CartListRepository lists,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return Router()
    ..route(
      '/carts',
      post(createCartEndpoint(creates, nextId: nextId, now: now), status: 201),
    )
    ..route('/carts/{id}', get(readCartEndpoint(reads)))
    ..route(
      '/carts/{id}/line-items',
      post(addLineEndpoint(reads, writes, catalog, nextId: nextId)),
    )
    ..route(
      '/carts/{id}/shipping-options',
      get(listShippingOptionsEndpoint(reads, lists)),
    )
    ..route(
      '/carts/{id}/shipping-method',
      post(chooseShippingEndpoint(reads, lists, writes)),
    )
    ..route(
      // Chained, not cascaded: MethodRouter is immutable, so `..delete(...)`
      // would build a router and throw it away, leaving DELETE a 405.
      '/carts/{id}/promotions',
      post(applyPromotionEndpoint(reads, writes, now: now))
          .delete(removePromotionEndpoint(reads, writes)),
    );
}
