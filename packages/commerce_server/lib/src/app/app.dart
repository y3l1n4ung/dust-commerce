import 'package:commerce_server/src/features/cart/cart.dart';
import 'package:commerce_server/src/features/catalog/catalog.dart';
import 'package:commerce_server/src/features/checkout/checkout.dart';
import 'package:commerce_server/src/features/payment/payment.dart';
import 'package:commerce_server/src/http/http.dart';
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
  final catalogReads = CatalogReadRepository(executor);
  final catalogLists = CatalogListRepository(executor);
  final cartCreates = CartCreateRepository(executor);
  final cartReads = CartReadRepository(executor);
  final cartLists = CartListRepository(executor);
  final cartWrites = CartUpdateRepository(executor);
  final orderReads = CheckoutReadRepository(executor);
  final orderLists = CheckoutListRepository(executor);
  final paymentReads = PaymentReadRepository(executor);
  final paymentWrites = PaymentCreateRepository(executor);
  final identify = nextId ?? _randomId;
  final clock = now ?? DateTime.now;

  return Router()
    ..nest('/store', catalogRoutes(catalogReads, catalogLists))
    ..nest(
      '/store',
      cartRoutes(
        cartCreates,
        cartReads,
        cartLists,
        cartWrites,
        catalogReads,
        nextId: identify,
        now: clock,
      ),
    )
    ..nest(
      '/store',
      checkoutRoutes(
        database,
        orderReads,
        orderLists,
        nextId: identify,
        now: clock,
      ),
    )
    ..nest(
      '/store',
      paymentRoutes(),
    )
    ..withState(
      PaymentDeps(
        database: database,
        orders: orderReads,
        reads: paymentReads,
        writes: paymentWrites,
        clock: Clock(now: clock, nextId: identify),
      ),
    )
    ..route('/health', get((_) async => jsonResponse({'status': 'ok'})));
}

int _counter = 0;

String _randomId() =>
    'id_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
