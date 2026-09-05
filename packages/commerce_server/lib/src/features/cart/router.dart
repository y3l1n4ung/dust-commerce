import 'package:commerce_server/src/features/cart/handler/handler.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_server/server.dart';

/// The cart's routes, mounted by the application under a prefix.
Router cartRoutes(
  CartRepository carts,
  CatalogRepository catalog, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return Router()
    ..route(
      '/carts',
      post(createCartHandler(carts, nextId: nextId, now: now)),
    )
    ..route('/carts/{id}', get(getCartHandler(carts)))
    ..route(
      '/carts/{id}/line-items',
      post(addLineHandler(carts, catalog, nextId: nextId)),
    );
}
