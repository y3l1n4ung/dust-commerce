import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/i18n/app_i18n.g.dart';
import 'package:commerce_app/main.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customer opens a product and adds the selected variant',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppI18n(child: CommerceApp(api: _FakeCommerceApi())),
    );
    await tester.pumpAndSettle();

    final shirt = find.text('Dust T-Shirt');
    expect(shirt, findsOneWidget);
    await tester.scrollUntilVisible(
      shirt,
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(shirt);
    await tester.pumpAndSettle();

    expect(find.text('A soft cotton essential.'), findsOneWidget);
    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(find.text('Cart (1)'), findsOneWidget);
  });
}

final class _FakeCommerceApi implements CommerceApi {
  _FakeCommerceApi() : _cart = CartView.of(_emptyCart);

  CartView _cart;

  @override
  Future<ProductPageView> products({
    String? currency,
    int? limit,
    int? offset,
  }) async =>
      ProductPageView(
        products: [_product],
        count: 1,
        total: 1,
        limit: limit ?? 20,
        offset: offset ?? 0,
      );

  @override
  Future<Product> product(String handle, {String? currency}) async => _product;

  @override
  Future<CartView> createCart() async => _cart;

  @override
  Future<CartView> addLine(String id, AddLineBody body) async {
    final line = LineItem.fromVariant(
      id: 'line_m',
      productId: _product.id,
      productTitle: _product.title,
      variant: _variant,
      currencyCode: 'usd',
      quantity: 1,
    );
    return _cart = CartView.of(_cart.cart.withLine(line));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _variant = ProductVariant.of(
  id: 'variant_m',
  title: 'M',
  prices: [Money.of(1500, 'usd')],
  inventoryQuantity: 5,
  optionValues: const {'size': 'M'},
);

final _product = Product.of(
  id: 'product_tshirt',
  title: 'Dust T-Shirt',
  handle: 't-shirt',
  description: 'A soft cotton essential.',
  status: ProductStatus.published,
  options: [
    ProductOption.of(id: 'size', title: 'Size', values: ['M']),
  ],
  variants: [_variant],
);

final _emptyCart = Cart.of(
  id: 'cart_test',
  region: Region.of(
    id: 'region_us',
    name: 'United States',
    currencyCode: 'usd',
    taxRate: 1000,
    countries: ['us'],
  ),
);
