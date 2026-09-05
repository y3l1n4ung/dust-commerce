import 'package:commerce_server/src/features/cart/handler/handler.dart';
import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_server/server.dart';

/// The cart's routes, mounted by the application under a prefix.
Router cartRoutes(
  CartCreateRepository creates,
  CartReadRepository reads,
  CartUpdateRepository writes,
  CatalogReadRepository catalog, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return Router()
    ..route(
      '/carts',
      post(createCartHandler(creates, nextId: nextId, now: now)),
    )
    ..route('/carts/{id}', get(readCartHandler(reads)))
    ..route(
      '/carts/{id}/line-items',
      post(addLineHandler(reads, writes, catalog, nextId: nextId)),
    );
}
