import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late CheckoutHarness harness;

  setUp(() async => harness = await CheckoutHarness.start());
  tearDown(() async => harness.stop());

  group('POST /store/checkout', () {
    test('turns a cart into an order with frozen totals', () async {
      final cartId = await harness.cartWith('var_small', quantity: 2);

      final response = await harness.checkout(cartId);

      response.assertCreated();
      final order = Order.fromJson(response.json! as Map<String, Object?>);

      expect(order.items, hasLength(1));
      expect(order.subtotal, Money.of(3998, 'usd'));
      expect(order.tax, Money.of(400, 'usd'));
      expect(order.total, Money.of(4398, 'usd'));
      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaiting);
    });

    test('takes the stock it sold', () async {
      final cartId = await harness.cartWith('var_large', quantity: 2);

      (await harness.checkout(cartId)).assertCreated();

      expect(await harness.stockOf('var_large'), 0);
    });

    test('empties the cart it ordered', () async {
      final cartId = await harness.cartWith('var_small');

      (await harness.checkout(cartId)).assertCreated();

      final response = await harness.client.get('/store/carts/$cartId').send();
      final cart = Cart.fromJson(response.json! as Map<String, Object?>);

      expect(cart.isEmpty, isTrue);
    });
  });

  group('when somebody else got there first', () {
    test('answers 409 and takes no more stock', () async {
      final mine = await harness.cartWith('var_large', quantity: 2);
      final theirs = await harness.cartWith('var_large', quantity: 2);

      (await harness.checkout(theirs)).assertCreated();
      (await harness.checkout(mine)).assertConflict();

      expect(await harness.stockOf('var_large'), 0);
    });

    test('leaves no order behind', () async {
      final mine = await harness.cartWith('var_large', quantity: 2);
      final theirs = await harness.cartWith('var_large', quantity: 2);

      (await harness.checkout(theirs)).assertCreated();
      (await harness.checkout(mine, email: 'loser@example.com'))
          .assertConflict();

      (await harness.client.get('/store/orders?email=loser@example.com').send())
        ..assertOk()
        ..assertJsonContains({'count': 0});
    });
  });

  group('what it refuses', () {
    test('a cart nobody started', () async {
      (await harness.checkout('nope')).assertNotFound();
    });

    test('an empty cart', () async {
      final created = await harness.client.post('/store/carts').send();
      final cartId = (created.json! as Map<String, Object?>)['id']! as String;

      (await harness.checkout(cartId)).assertUnprocessable();
    });

    test('an address that is not an email, naming the field', () async {
      final cartId = await harness.cartWith('var_small');

      (await harness.checkout(cartId, email: 'not-an-email'))
        ..assertUnprocessable()
        ..assertTextContains('validation_failed')
        ..assertTextContains('email');
    });

    test('a shipping address missing its recipient', () async {
      final cartId = await harness.cartWith('var_small');

      (await harness.checkout(
        cartId,
        shipping: harness.address(firstName: ''),
      ))
          .assertUnprocessable();
    });
  });
}
