import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late CheckoutHarness harness;

  setUp(() async => harness = await CheckoutHarness.start());
  tearDown(() async => harness.stop());

  Future<String> placeOrder({String email = 'ada@example.com'}) async {
    final cartId = await harness.cartWith('var_small');
    final placed = await harness.checkout(cartId, email: email);
    placed.assertCreated();
    return (placed.json! as Map<String, Object?>)['id']! as String;
  }

  group('GET /store/orders', () {
    test('lists only the orders of the email that asks', () async {
      await placeOrder();
      await placeOrder(email: 'grace@example.com');

      (await harness.client.get('/store/orders?email=ada@example.com').send())
        ..assertOk()
        ..assertJsonContains({'count': 1});
    });

    test('requires an email rather than listing everything', () async {
      (await harness.client.get('/store/orders').send()).assertBadRequest();
    });
  });

  group('GET /store/orders/{id}', () {
    test('returns the order to the address that placed it', () async {
      final id = await placeOrder();

      final response = await harness.client
          .get('/store/orders/$id?email=ada@example.com')
          .send();

      response.assertOk();
      final order = Order.fromJson(response.json! as Map<String, Object?>);

      expect(order.id, id);
      expect(order.shippingAddress.city, 'London');
      expect(order.billingAddress, order.shippingAddress);
    });

    test('will not hand an order to somebody else who knows the id', () async {
      final id = await placeOrder();

      (await harness.client
              .get('/store/orders/$id?email=grace@example.com')
              .send())
          .assertNotFound();
    });

    test('requires an email at all', () async {
      final id = await placeOrder();

      (await harness.client.get('/store/orders/$id').send()).assertBadRequest();
    });
  });
}
