import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/support.dart';

void main() {
  test('product and checkout routes retain Medusa query state', () {
    final product = parseCommerceRoute(
      Uri.parse('/products/t-shirt?v_id=var_tshirt_m_white'),
    );
    final checkout = parseCommerceRoute(
      Uri.parse('/checkout?step=payment'),
    );

    expect(product.location, '/products/t-shirt?v_id=var_tshirt_m_white');
    expect(
      generatedRouteUriExtrasOf(product)?.queryParameters['v_id'],
      ['var_tshirt_m_white'],
    );
    expect(checkout.location, '/checkout?step=payment');
    expect(
      generatedRouteUriExtrasOf(checkout)?.queryParameters['step'],
      ['payment'],
    );
  });

  test('router preserves the browser location on its first parse', () {
    const api = _UnusedApi();
    final router = CommerceRouter(
      initialLocation: Uri.parse('/products/t-shirt?v_id=var_tshirt_m_white'),
      account: testAccount(api),
      cart: testCart(api),
    );

    final restored = router.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/')),
    );
    final later = router.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/cart')),
    );

    expect(
      restored.uri.toString(),
      '/products/t-shirt?v_id=var_tshirt_m_white',
    );
    expect(later.uri.toString(), '/cart');
  });

  test('checkout route rejects an empty cart at route level', () async {
    const api = _UnusedApi();
    final cart = testCart(api);
    final router = CommerceRouter(
      initialLocation: Uri.parse('/checkout'),
      account: testAccount(api),
      cart: cart,
    );
    const route = CheckoutRoute();
    final guards = commerceRouteGuards(route, router);

    expect(guards.single, isA<CheckoutGuard>());
    expect(
      await RouteGuardChain<CommerceRoute>(guards).canActivate(route),
      isA<CartRoute>(),
    );
  });
}

final class _UnusedApi implements CommerceApi {
  const _UnusedApi();

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No API request expected');
}
