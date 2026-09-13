import 'package:commerce_server/src/features/account/account.dart';
import 'package:commerce_server/src/features/admin/admin.dart';
import 'package:commerce_server/src/features/admin_order/admin_order.dart';
import 'package:commerce_server/src/features/admin_region/admin_region.dart';
import 'package:commerce_server/src/features/cart/cart.dart';
import 'package:commerce_server/src/features/category/category.dart';
import 'package:commerce_server/src/features/catalog/catalog.dart';
import 'package:commerce_server/src/features/checkout/checkout.dart';
import 'package:commerce_server/src/features/collection/collection.dart';
import 'package:commerce_server/src/features/order_transfer/order_transfer.dart';
import 'package:commerce_server/src/features/payment/payment.dart';
import 'package:commerce_server/src/features/region/region.dart';
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
  PasswordWorkLimiter? passwordWork,
  AdminMediaStorage mediaStorage = const UnavailableAdminMediaStorage(),
  EmailVerificationMailer emailVerificationMailer =
      const UnavailableEmailVerificationMailer(),
  OrderTransferMailer orderTransferMailer =
      const UnavailableOrderTransferMailer(),
  bool requireEmailVerification = false,
}) {
  final executor = database.executor;
  final clock = Clock(now: now ?? DateTime.now, nextId: nextId ?? _randomId);

  final catalogReads = CatalogReadRepository(executor);
  final orderReads = CheckoutReadRepository(executor);
  final resolvedPasswordWork = passwordWork ?? PasswordWorkLimiter();
  final accountDeps = AccountDeps(
    database: database,
    reads: AccountReadRepository(executor),
    lists: AccountListRepository(executor),
    writes: AccountCreateRepository(executor),
    updates: AccountUpdateRepository(executor),
    deletes: AccountDeleteRepository(executor),
    emailVerificationMailer: emailVerificationMailer,
    clock: clock,
    passwordWork: resolvedPasswordWork,
    requireEmailVerification: requireEmailVerification,
  );

  return Router()
    ..nest('/auth', accountAuthRoutes())
    ..nest('/auth', adminAuthRoutes())
    ..nest('/admin', adminRoutes())
    ..merge(adminMediaRoutes())
    ..nest('/store', accountStoreRoutes())
    ..nest('/store', categoryRoutes())
    ..nest('/store', catalogRoutes())
    ..nest('/store', collectionRoutes())
    ..nest('/store', cartRoutes())
    ..nest('/store', checkoutRoutes())
    ..nest('/store', orderTransferRoutes())
    ..nest('/store', paymentRoutes())
    ..nest('/store', regionRoutes())
    ..route('/health', get(_health))
    ..withState(accountDeps)
    ..withState(
      AdminDeps(
        database: database,
        reads: AdminReadRepository(executor),
        writes: AdminCreateRepository(executor),
        deletes: AdminDeleteRepository(executor),
        clock: clock,
        passwordWork: resolvedPasswordWork,
        dummyPasswordHash: accountDeps.dummyPasswordHash,
        products: AdminProductRepository(executor),
        productExports: AdminProductExportRepository(executor),
        productImports: AdminProductImportRepository(executor),
        productTags: AdminProductTagRepository(executor),
        productTypes: AdminProductTypeRepository(executor),
        productTypeReads: AdminProductTypeReadRepository(executor),
        productOptions: AdminProductOptionRepository(executor),
        productCreates: AdminProductCreateRepository(executor),
        productReads: AdminProductReadRepository(executor),
        media: AdminMediaRepository(executor),
        mediaStorage: mediaStorage,
      ),
    )
    ..withState(
      AdminOrderDeps(
        orders: AdminOrderRepository(executor),
        details: AdminOrderDetailRepository(executor),
        exports: AdminOrderExportRepository(executor),
      ),
    )
    ..withState(AdminRegionDeps(regions: AdminRegionRepository(executor)))
    ..withState(
      CatalogDeps(
        reads: catalogReads,
        lists: CatalogListRepository(executor),
        counts: CatalogCountRepository(executor),
        options: CatalogOptionRepository(executor),
      ),
    )
    ..withState(
      CategoryDeps(categories: ProductCategoryRepository(executor)),
    )
    ..withState(
      CollectionDeps(collections: ProductCollectionRepository(executor)),
    )
    ..withState(
      CartDeps(
        creates: CartCreateRepository(executor),
        reads: CartReadRepository(executor),
        lists: CartListRepository(executor),
        writes: CartUpdateRepository(executor),
        catalog: catalogReads,
        clock: clock,
        database: database,
        shipping: CartShippingRepository(executor),
        payments: CartPaymentRepository(executor),
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
        clock: clock,
      ),
    )
    ..withState(
      OrderTransferDeps(
        database: database,
        reads: OrderTransferReadRepository(executor),
        creates: OrderTransferCreateRepository(executor),
        updates: OrderTransferUpdateRepository(executor),
        clock: clock,
        mailer: orderTransferMailer,
      ),
    )
    ..withState(RegionDeps(regions: SellingRegionRepository(executor)));
}

/// `GET /health` — the shallowest possible answer that the process is up.
Map<String, Object?> _health(Request request) => const {'status': 'ok'};

String _randomId() => 'id_${Tokens.issue()}';
