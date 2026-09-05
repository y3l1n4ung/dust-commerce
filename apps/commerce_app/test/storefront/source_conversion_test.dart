import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
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

  test('related products come from the API and exclude the current item',
      () async {
    final product = ProductViewModel(ProductViewModelArgs(api: api));

    await product.load('t-shirt');

    expect(product.state.relatedStatus, RelatedProductsStatus.ready);
    expect(product.state.relatedProducts, hasLength(3));
    expect(
      product.state.relatedProducts.map((item) => item.id),
      isNot(contains('prod_tshirt')),
    );
    expect(
      product.state.relatedProducts.every(
        (item) => item.cheapestIn(product.state.currencyCode) != null,
      ),
      isTrue,
    );
  });

  test('an empty related result does not hide the main product', () async {
    await queryExecute(
      "DELETE FROM products WHERE id <> 'prod_tshirt'",
      const [],
    ).execute(database.executor);
    final product = ProductViewModel(ProductViewModelArgs(api: api));

    await product.load('t-shirt');

    expect(product.state.status, ProductDetailStatus.ready);
    expect(product.state.relatedStatus, RelatedProductsStatus.ready);
    expect(product.state.relatedProducts, isEmpty);
  });

  test('a related-products failure leaves the main product usable', () async {
    final product = ProductViewModel(
      ProductViewModelArgs(api: _RelatedFailureApi(api)),
    );

    await product.load('t-shirt');

    expect(product.state.status, ProductDetailStatus.ready);
    expect(product.state.product?.id, 'prod_tshirt');
    expect(product.state.relatedStatus, RelatedProductsStatus.failed);
    expect(product.state.relatedMessage, isNotNull);
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
    final cart = CartViewModel(
      CartViewModelArgs(api: api, cartIds: _MemoryCartIdStore()),
    );
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

final class _RelatedFailureApi implements CommerceApi {
  const _RelatedFailureApi(this.delegate);

  final CommerceApi delegate;

  @override
  Future<Product> product(String handle, {String? currency}) =>
      delegate.product(handle, currency: currency);

  @override
  Future<ProductPageView> products({
    String? currency,
    int? limit,
    int? offset,
  }) =>
      Future.error(StateError('recommendations unavailable'));

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused API method');
}

final class _MemoryCartIdStore implements CartIdStore {
  final Map<String, String> _values = {};

  @override
  Future<void> clear(String scope) async => _values.remove(scope);

  @override
  Future<String?> read(String scope) async => _values[scope];

  @override
  Future<void> write(String scope, String cartId) async {
    _values[scope] = cartId;
  }
}
