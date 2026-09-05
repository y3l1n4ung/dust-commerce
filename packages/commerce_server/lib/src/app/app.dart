import 'package:commerce_server/src/features/catalog/catalog.dart';
import 'package:dust_dart/db.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_server/server.dart';

/// Mounts every feature's routes onto one router.
///
/// This is the only file that knows the shape of the whole application, and it
/// knows nothing about what any handler does. A feature is added here in one
/// line or it is not reachable.
///
/// Repositories wrap the database's connection rather than owning it, so
/// building one is free and the application closes the database exactly once.
Router buildApp(CommerceDatabase database) {
  final catalog = CatalogRepository(database.executor);

  return Router()
    ..nest('/store', catalogRoutes(catalog))
    ..route('/health', get((_) async => jsonResponse({'status': 'ok'})));
}
