import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('order history uses a typed route-level customer guard', () async {
    final account = testAccount(const _UnusedApi());
    final router = CommerceRouter(
      initialLocation: Uri.parse('/account/orders'),
      account: account,
      cart: testCart(const _UnusedApi()),
    );
    const route = AccountOrdersRoute();
    final guards = commerceRouteGuards(route, router);

    expect(guards.single, isA<CustomerGuard>());
    expect(
      await RouteGuardChain<CommerceRoute>(guards).canActivate(route),
      isA<AccountRoute>(),
    );
  });

  test('the shared sign-in account route remains public', () {
    final router = CommerceRouter(
      initialLocation: Uri.parse('/account'),
      account: testAccount(const _UnusedApi()),
      cart: testCart(const _UnusedApi()),
    );

    expect(commerceRouteGuards(const AccountRoute(), router), isEmpty);
  });

  test('signed-out guarded navigation settles on the account route', () async {
    final router = CommerceRouter(
      initialLocation: Uri.parse('/account/orders'),
      account: testAccount(const _UnusedApi()),
      cart: testCart(const _UnusedApi()),
    );
    final delegate =
        router.config.routerDelegate as GeneratedRouterDelegate<CommerceRoute>;

    await delegate.debugWaitForScheduledRefresh();
    await delegate.setNewRoutePath(const AccountOrdersRoute());

    expect(delegate.currentConfiguration, isA<AccountRoute>());
  });
}

final class _UnusedApi implements CommerceApi {
  const _UnusedApi();

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No API request expected');
}
