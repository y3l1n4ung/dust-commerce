import 'package:commerce_server/src/features/cart/cart.dart';
import 'package:commerce_server/src/features/catalog/catalog.dart';
import 'package:commerce_server/src/features/checkout/checkout.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

/// Mounts every feature's routes onto one router.
///
/// This is the only file that knows the shape of the whole application, and it
/// knows nothing about what any handler does. A feature is added here in one
/// line or it is not reachable.
///
/// Identifiers and the clock are injected rather than reached for. A test that
/// cannot choose them has to assert around them instead of on them.
Router buildApp(
  CommerceDatabase database, {
  String Function()? nextId,
  DateTime Function()? now,
}) {
  final executor = database.executor;
  final catalog = CatalogRepository(executor);
  final carts = CartRepository(executor);
  final orders = CheckoutRepository(executor);
  final identify = nextId ?? _randomId;
  final clock = now ?? DateTime.now;

  return Router()
    ..nest('/store', catalogRoutes(catalog))
    ..nest('/store', cartRoutes(carts, catalog, nextId: identify, now: clock))
    ..nest(
      '/store',
      checkoutRoutes(database, orders, nextId: identify, now: clock),
    )
    ..route('/health', get((_) async => jsonResponse({'status': 'ok'})));
}

int _counter = 0;

String _randomId() =>
    'id_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
