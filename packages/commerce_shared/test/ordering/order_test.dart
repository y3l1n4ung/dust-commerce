import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

void main() {
  final region = Region.of(
    id: 'reg_eu',
    name: 'Europe',
    currencyCode: 'eur',
    taxRate: 2000,
    countries: const ['de'],
  );

  final address = Address.of(
    firstName: 'Ada',
    lastName: 'Lovelace',
    line1: '12 Analytical Way',
    city: 'Berlin',
    postalCode: '10115',
    countryCode: 'DE',
  );

  LineItem line({int unitPrice = 1000, int quantity = 2}) => LineItem.of(
        id: 'item_1',
        variantId: 'variant_1',
        productId: 'prod_1',
        title: 'T-Shirt',
        unitPrice: Money.of(unitPrice, 'eur'),
        quantity: quantity,
      );

  Cart cart({List<LineItem>? items}) => Cart.of(
        id: 'cart_1',
        region: region,
        items: items ?? [line()],
        email: 'ada@example.com',
      );

  Order placed({Cart? from}) => Order.fromCart(
        id: 'order_1',
        cart: from ?? cart(),
        shippingAddress: address,
        placedAt: DateTime.utc(2026, 9, 5),
      );

  group('Order.fromCart', () {
    test('freezes the totals rather than recomputing them', () {
      final order = placed();

      expect(order.subtotal, Money.of(2000, 'eur'));
      expect(order.tax, Money.of(400, 'eur'));
      expect(order.total, Money.of(2400, 'eur'));
    });

    test('copies the lines, so a later cart change cannot reach it', () {
      final source = cart();
      final order = placed(from: source);

      final emptied = source.withoutLine('item_1');

      expect(emptied.items, isEmpty);
      expect(order.items, hasLength(1));
      expect(order.items.single.unitPrice, Money.of(1000, 'eur'));
    });

    test('refuses an empty cart, which is nothing to order', () {
      expect(
        () => placed(from: Cart.of(id: 'cart_1', region: region)),
        throwsArgumentError,
      );
    });

    test('refuses a cart with no email to reach the buyer on', () {
      final anonymous = Cart.of(id: 'c', region: region, items: [line()]);

      expect(() => placed(from: anonymous), throwsArgumentError);
    });

    test('starts pending, and is not yet paid', () {
      final order = placed();

      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaiting);
      expect(order.isPaid, isFalse);
    });

    test('bills to the shipping address unless told otherwise', () {
      expect(placed().billingAddress, address);
    });
  });

  group('lifecycle', () {
    test('capturing payment marks it paid and completes the order', () {
      final captured = placed().captured();

      expect(captured.paymentStatus, PaymentStatus.captured);
      expect(captured.isPaid, isTrue);
      expect(captured.status, OrderStatus.completed);
    });

    test('cancelling a pending order leaves the payment awaiting', () {
      final cancelled = placed().cancelled();

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.paymentStatus, PaymentStatus.awaiting);
    });

    test('refuses to cancel an order already paid', () {
      expect(() => placed().captured().cancelled(), throwsStateError);
    });

    test('refuses to capture an order already cancelled', () {
      expect(() => placed().cancelled().captured(), throwsStateError);
    });
  });

  group('json', () {
    test('round-trips through the generated codec', () {
      expect(Order.fromJson(placed().toJson()), placed());
    });

    test('encodes status as its wire name', () {
      expect(placed().toJson()['status'], 'pending');
      expect(placed().toJson()['payment_status'], 'awaiting');
    });
  });
}
