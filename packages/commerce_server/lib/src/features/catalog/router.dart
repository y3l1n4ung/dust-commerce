import 'package:commerce_server/src/features/catalog/handler/handler.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_server/server.dart';

/// The catalogue's routes, mounted by the application under a prefix.
///
/// The feature declares its own paths. Nothing outside this file needs to know
/// that a product is fetched by handle rather than by id.
Router catalogRoutes(
  CatalogReadRepository reads,
  CatalogListRepository lists,
) {
  return Router()
    ..route('/products', get(listProductsEndpoint(lists)))
    ..route('/products/{handle}', get(readProductEndpoint(reads, lists)));
}
