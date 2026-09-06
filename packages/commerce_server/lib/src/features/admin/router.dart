import 'package:commerce_server/src/features/admin/extractor.dart';
import 'package:commerce_server/src/features/admin/handler/handler.dart';
import 'package:dust_server/server.dart';

/// Authentication routes for the distinct admin actor type.
Router adminAuthRoutes() {
  final protected = Router()
    ..routeLayer(fromExtractor(const AdminAuth()))
    ..route('/admin/session', delete(adminSignOutHandler));

  return Router()
    ..route('/admin/emailpass', post(adminSignInHandler))
    ..merge(protected);
}

/// Merchant-only routes guarded once at the route-tree boundary.
Router adminRoutes() => Router()
  ..routeLayer(fromExtractor(const AdminAuth()))
  ..route('/users/me', get(readCurrentAdminHandler))
  ..route(
    '/products',
    get(listAdminProductsHandler).post(createAdminProductHandler),
  )
  ..route(
    '/products/create-context',
    get(readAdminProductCreateContextHandler),
  )
  ..route(
    '/products/{id}',
    get(readAdminProductHandler).patch(updateAdminProductHandler),
  );
