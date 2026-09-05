import 'package:commerce_server/src/features/cart/cart.dart';
import 'package:commerce_server/src/features/catalog/catalog.dart';
import 'package:commerce_server/src/features/checkout/checkout.dart';
import 'package:commerce_server/src/features/payment/payment.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

/// Mounts every feature's routes and attaches the state they ask for.
///
/// This is the only file that knows the shape of the whole application, and it
/// knows nothing about what any handler does. A feature is added here in two
/// lines — its routes and its dependencies — or it is not reachable.
///
/// Dependencies travel as state rather than as arguments to a handler factory,
/// which is the pattern dust_server is built around and what a generated
/// `@State()` parameter lowers to. The trade is real and worth naming: a
/// dependency nobody attached is a 500 at request time rather than a compile
/// error here. The feature tests are the guard, because every one of them
/// builds this router and exercises its routes.
///
/// Identifiers and the clock are injected rather than reached for. A test that
/// cannot choose them has to assert around them instead of on them.
Router buildApp(
  CommerceDatabase database, {
  String Function()? nextId,
  DateTime Function()? now,
}) {
  final executor = database.executor;
  final clock = Clock(now: now ?? DateTime.now, nextId: nextId ?? _randomId);

  final catalogReads = CatalogReadRepository(executor);
  final orderReads = CheckoutReadRepository(executor);

  return Router()
    ..nest('/store', catalogRoutes())
    ..nest('/store', cartRoutes())
    ..nest('/store', checkoutRoutes())
    ..nest('/store', paymentRoutes())
    ..route('/health', get(_health))
    ..withState(
      CatalogDeps(
        reads: catalogReads,
        lists: CatalogListRepository(executor),
      ),
    )
    ..withState(
      CartDeps(
        creates: CartCreateRepository(executor),
        reads: CartReadRepository(executor),
        lists: CartListRepository(executor),
        writes: CartUpdateRepository(executor),
        catalog: catalogReads,
        clock: clock,
      ),
    )
    ..withState(
      CheckoutDeps(
        database: database,
        reads: orderReads,
        lists: CheckoutListRepository(executor),
        clock: clock,
      ),
    )
    ..withState(
      PaymentDeps(
        database: database,
        orders: orderReads,
        reads: PaymentReadRepository(executor),
        writes: PaymentCreateRepository(executor),
        clock: clock,
      ),
    );
}

/// `GET /health` — the shallowest possible answer that the process is up.
Map<String, Object?> _health(Request request) => const {'status': 'ok'};

int _counter = 0;

String _randomId() =>
    'id_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
