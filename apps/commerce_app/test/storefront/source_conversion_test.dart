import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
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
    expect(product.state.product?.variants, hasLength(4));
    expect(product.state.selectedVariant, isNull);

    product.select('opt_tshirt_size', 'M');

    expect(product.state.selectedVariant?.id, 'var_tshirt_m');
    expect(product.state.selectedVariant?.isInStock, isTrue);
  });

  test('selected variant creates a server cart and line item', () async {
    final product = await api.product('t-shirt', currency: 'usd');
    final cart = CartViewModel(CartViewModelArgs(api: api));
    final small = product.variants.firstWhere(
      (variant) => variant.id == 'var_tshirt_s',
    );

    final added = await cart.add(small);

    expect(added, isTrue);
    expect(cart.state.status, CartStatus.ready);
    expect(cart.state.itemCount, 1);
    expect(cart.state.cart?.cart.items.single.variantId, 'var_tshirt_s');
    expect(cart.state.cart?.total.amount, greaterThan(0));
  });
}
