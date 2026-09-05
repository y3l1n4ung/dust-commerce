import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late CommerceApi api;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('storefront_flow');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedDevelopmentStore(database);
    server = await TestClient.serve(buildApp(database));
    api = CommerceApi(Dio(), baseUrl: server.origin);
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('catalogue product options resolve to a real variant', () async {
    final product = ProductViewModel(ProductViewModelArgs(api: api));

    await product.load('t-shirt');
    expect(product.state.status, ProductDetailStatus.ready);
    expect(product.state.product?.variants, hasLength(8));
    expect(product.state.selectedVariant, isNull);

    product.select('opt_tshirt_size', 'M');
    expect(product.state.selectedVariant, isNull);
    product.select('opt_tshirt_color', 'White');

    expect(product.state.selectedVariant?.id, 'var_tshirt_m_white');
    expect(product.state.selectedVariant?.isInStock, isTrue);
  });

  test('a Medusa v_id restores the complete product selection', () async {
    final product = ProductViewModel(ProductViewModelArgs(api: api));

    await product.load('t-shirt', variantId: 'var_tshirt_l_black');

    expect(product.state.selection, {
      'opt_tshirt_color': 'Black',
      'opt_tshirt_size': 'L',
    });
    expect(product.state.selectedVariant?.id, 'var_tshirt_l_black');
  });

  test('the product route round-trips Medusa unknown query extras', () {
    final route = parseCommerceRoute(
      Uri.parse('/products/t-shirt?v_id=var_tshirt_m_white'),
    );

    expect(route, isA<ProductRoute>());
    expect(route.location, '/products/t-shirt?v_id=var_tshirt_m_white');
    expect(
      generatedRouteUriExtrasOf(route)?.queryParameters['v_id'],
      ['var_tshirt_m_white'],
    );
  });

  test('router preserves the browser location on its first parse', () {
    final router = CommerceRouter(
      initialLocation: Uri.parse('/products/t-shirt?v_id=var_tshirt_m_white'),
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

  test('option choices exclude combinations no variant can fulfil', () async {
    final product = await api.product('t-shirt', currency: 'usd');
    final sparse = product.copyWith(
      variants: product.variants
          .where((variant) =>
              variant.id == 'var_tshirt_s_black' ||
              variant.id == 'var_tshirt_m_white')
          .toList(),
    );
    final state = ProductDetailState(
      status: ProductDetailStatus.ready,
      product: sparse,
      selection: const {'opt_tshirt_size': 'S'},
    );

    expect(state.canSelect('opt_tshirt_color', 'Black'), isTrue);
    expect(state.canSelect('opt_tshirt_color', 'White'), isFalse);
  });

  test('selected variant creates a server cart and line item', () async {
    final product = await api.product('t-shirt', currency: 'usd');
    final cart = CartViewModel(CartViewModelArgs(api: api));
    final small = product.variants.firstWhere(
      (variant) => variant.id == 'var_tshirt_s_black',
    );

    final added = await cart.add(small);

    expect(added, isTrue);
    expect(cart.state.status, CartStatus.ready);
    expect(cart.state.itemCount, 1);
    expect(
      cart.state.cart?.cart.items.single.variantId,
      'var_tshirt_s_black',
    );
    expect(cart.state.cart?.total.amount, greaterThan(0));
  });
}
