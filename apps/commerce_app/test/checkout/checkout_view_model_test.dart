import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/support.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late CommerceApi api;
  late MemoryCartIdStore cartIds;
  late CartViewModel cart;
  late _MemoryReceiptStore receipts;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('checkout_view_model');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedDevelopmentStore(database);
    server = await TestClient.serve(buildApp(database));
    api = CommerceApi(Dio(), baseUrl: server.origin);
    cartIds = MemoryCartIdStore();
    cart = testCart(api, storage: cartIds);
    receipts = _MemoryReceiptStore();
    await cart.restore();
    final product = await api.product('t-shirt');
    await cart.add(product.variants.first);
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  CheckoutViewModel checkout({CommerceApi? client}) => CheckoutViewModel(
        CheckoutViewModelArgs(
          api: client ?? api,
          cart: cart,
          receipts: receipts,
          currentCustomer: () => null,
        ),
      );

  test('guest checkout completes every source step without duplicate totals',
      () async {
    final model = checkout()..prepare();
    expect(
        await CheckoutGuard(cart).canActivate(const CheckoutRoute()), isNull);

    expect(_saveAddress(model), isTrue);
    expect(await model.loadDelivery(), isTrue);
    expect(await model.chooseDelivery('ship_standard'), isTrue);
    model.selectManualPayment();
    expect(await model.placeOrder(), isTrue);

    final order = model.state.order!;
    expect(model.state.status, CheckoutStatus.complete);
    expect(order.paymentStatus, PaymentStatus.captured);
    expect(order.status, OrderStatus.completed);
    expect(cart.state.cart, isNull);
    expect(cartIds.values, isNot(contains('guest')));
    expect((await receipts.read(order.id))?.id, order.id);

    final restored = checkout();
    expect(await restored.loadReceipt(order.id), isTrue);
    expect(restored.state.order, order);
  });

  test('capture failure retains input and resumes the same order', () async {
    final model = checkout(client: _FailFirstCaptureApi(api))..prepare();
    _saveAddress(model);
    await model.loadDelivery();
    await model.chooseDelivery('ship_standard');
    model.selectManualPayment();

    expect(await model.placeOrder(), isFalse);
    final placedId = model.state.order!.id;
    expect(model.state.status, CheckoutStatus.failed);
    expect(model.state.shipping.line1, '12 Analytical Way');

    expect(await model.placeOrder(), isTrue);
    expect(model.state.order!.id, placedId);
    expect(model.state.order!.paymentStatus, PaymentStatus.captured);
  });
}

bool _saveAddress(CheckoutViewModel model) => model.saveAddresses(
      email: 'ada@example.com',
      shipping: const CheckoutAddressDraft(
        firstName: 'Ada',
        lastName: 'Lovelace',
        line1: '12 Analytical Way',
        city: 'London',
        postalCode: 'EC1A',
        countryCode: 'us',
      ),
      billing: const CheckoutAddressDraft(),
      sameAsBilling: true,
    );

final class _MemoryReceiptStore implements OrderReceiptStore {
  Order? value;

  @override
  Future<Order?> read(String orderId) async =>
      value?.id == orderId ? value : null;

  @override
  Future<void> write(Order order) async => value = order;
}

final class _FailFirstCaptureApi implements CommerceApi {
  _FailFirstCaptureApi(this.delegate);

  final CommerceApi delegate;
  bool failCapture = true;

  @override
  Future<Order> authorizePayment(String id, {String? guestEmail}) =>
      delegate.authorizePayment(id, guestEmail: guestEmail);

  @override
  Future<Order> capturePayment(String id, {String? guestEmail}) {
    if (failCapture) {
      failCapture = false;
      return Future.error(StateError('payment network interrupted'));
    }
    return delegate.capturePayment(id, guestEmail: guestEmail);
  }

  @override
  Future<Order> checkout(CheckoutRequest body) => delegate.checkout(body);

  @override
  Future<Order> order(String id) => delegate.order(id);

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused API method');
}
