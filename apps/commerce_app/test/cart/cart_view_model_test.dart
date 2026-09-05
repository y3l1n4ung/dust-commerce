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
  late _MemoryCartIdStore storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cart_view_model');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedDevelopmentStore(database);
    server = await TestClient.serve(buildApp(database));
    api = CommerceApi(Dio(), baseUrl: server.origin);
    storage = _MemoryCartIdStore();
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  CartViewModel model({String scope = 'guest'}) => CartViewModel(
        CartViewModelArgs(api: api, cartIds: storage, storageScope: scope),
      );

  Future<ProductVariant> variant() async =>
      (await api.product('t-shirt')).variantById('var_tshirt_m_white')!;

  test('persists and restores the opaque cart capability', () async {
    final first = model();
    await first.restore();
    expect(await first.add(await variant()), isTrue);
    final id = first.state.cart!.cart.id;
    expect(storage.values['guest'], id);
    expect(first.state.cart!.cart.items.single.title, 'Essential T-Shirt');
    expect(first.state.cart!.cart.items.single.productHandle, 't-shirt');

    final restarted = model();
    await restarted.restore();

    expect(restarted.state.status, CartStatus.ready);
    expect(restarted.state.cart?.cart.id, id);
    expect(restarted.state.itemCount, 1);
  });

  test('forgets a stale capability after the server returns 404', () async {
    storage.values['guest'] = 'missing';
    final restarted = model();

    await restarted.restore();

    expect(restarted.state.status, CartStatus.ready);
    expect(restarted.state.cart, isNull);
    expect(storage.values, isNot(contains('guest')));
  });

  test('quantity and removal always take totals from server responses',
      () async {
    final cart = model();
    await cart.restore();
    await cart.add(await variant());
    final line = cart.state.cart!.cart.items.single;

    expect(await cart.updateQuantity(line.id, 3), isTrue);
    expect(cart.state.itemCount, 3);
    expect(cart.state.cart!.subtotal.amount, line.unitPrice.amount * 3);

    expect(await cart.remove(line.id), isTrue);
    expect(cart.state.itemCount, 0);
    expect(cart.state.cart!.total, Money.zero('usd'));
  });

  test('promotion and shipping mutations retain authoritative totals',
      () async {
    final cart = model();
    await cart.restore();
    await cart.add(await variant());

    expect(await cart.loadShippingOptions(), isTrue);
    expect(cart.state.shippingOptions, hasLength(2));
    expect(await cart.chooseShipping('ship_standard'), isTrue);
    expect(cart.state.cart!.shippingTotal, Money.of(500, 'usd'));

    expect(await cart.applyPromotion('welcome10'), isTrue);
    expect(cart.state.cart!.cart.promotionCode, 'WELCOME10');
    expect(cart.state.cart!.discountTotal.amount, greaterThan(0));
    expect(await cart.removePromotion(), isTrue);
    expect(cart.state.cart!.cart.promotionCode, isNull);
    expect(cart.state.cart!.discountTotal, Money.zero('usd'));
  });

  test('storage scopes never overwrite one another', () async {
    final guest = model();
    final customer = model(scope: 'customer_1');
    await guest.restore();
    await customer.restore();
    await guest.add(await variant());
    await customer.add(await variant());

    expect(storage.values['guest'], isNot(storage.values['customer_1']));
  });
}

final class _MemoryCartIdStore implements CartIdStore {
  final Map<String, String> values = {};

  @override
  Future<void> clear(String scope) async => values.remove(scope);

  @override
  Future<String?> read(String scope) async => values[scope];

  @override
  Future<void> write(String scope, String cartId) async {
    values[scope] = cartId;
  }
}
