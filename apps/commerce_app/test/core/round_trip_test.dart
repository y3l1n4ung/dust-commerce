import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// The claim this repository exists to make, checked end to end.
///
/// The API is the real one, serving over a real socket. The client is the one
/// Dust generated from `CommerceApi`. Nothing here hand-writes a JSON map: the
/// server encodes with the shared models and the client decodes with the same
/// ones, so a field renamed in `commerce_shared` breaks this test at compile
/// time rather than in production.
void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late CommerceApi api;
  var counter = 0;

  setUp(() async {
    counter = 0;
    directory = await Directory.systemTemp.createTemp('commerce_round_trip');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await _seed(database);

    server = await TestClient.serve(
      buildApp(
        database,
        nextId: () => 'id_${++counter}',
        now: () => DateTime.utc(2026, 9, 5, 12),
      ),
    );
    api = CommerceApi(Dio(), baseUrl: server.origin);
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  group('the catalogue', () {
    test('decodes a page into the shared Product type', () async {
      final page = await api.products();

      expect(page.total, 1);
      expect(page.products, hasLength(1));

      final product = page.products.single;
      expect(product, isA<Product>());
      expect(product.handle, 't-shirt');
      expect(product.cheapestIn('usd'), Money.of(1999, 'usd'));
      expect(product.isPurchasable, isTrue);
    });

    test('decodes one product, keeping money as integer minor units', () async {
      final product = await api.product('t-shirt');

      expect(product.variants, hasLength(2));

      final small = product.variantById('var_small')!.priceIn('usd')!;
      expect(small.amount, isA<int>());
      expect(small, Money.of(1999, 'usd'));
      expect(product.cheapestIn('usd'), Money.of(1999, 'usd'));
    });

    test('prices in the currency the client asks for', () async {
      final product = await api.product('t-shirt', currency: 'eur');

      expect(product.cheapestIn('eur'), Money.of(1799, 'eur'));
      expect(product.cheapestIn('usd'), isNull);
    });
  });

  group('the cart', () {
    test('is created, added to, and totalled by the server', () async {
      final created = await api.createCart();
      expect(created.isEmpty, isTrue);

      final withLine = await api.addLine(
        created.id,
        const AddLineRequest(variantId: 'var_small', quantity: 2),
      );

      expect(withLine.itemCount, 2);
      expect(withLine.items.single.unitPrice, Money.of(1999, 'usd'));
      expect(withLine.subtotal, Money.of(3998, 'usd'));
      expect(withLine.tax, Money.of(400, 'usd'));
      expect(withLine.total, Money.of(4398, 'usd'));
    });

    test('agrees with the domain model computing the same totals', () async {
      final created = await api.createCart();
      final response = await api.addLine(
        created.id,
        const AddLineRequest(variantId: 'var_small', quantity: 3),
      );

      final locally = Cart.of(
        id: response.id,
        region: response.region,
        items: response.items,
      );

      expect(locally.subtotal, response.subtotal);
      expect(locally.tax, response.tax);
      expect(locally.total, response.total);
    });
  });

  group('checkout', () {
    test('places an order the client decodes as the shared Order', () async {
      final cart = await api.createCart();
      await api.addLine(
        cart.id,
        const AddLineRequest(variantId: 'var_small', quantity: 2),
      );

      final order = await api.checkout(
        CheckoutRequest(
          cartId: cart.id,
          email: 'ada@example.com',
          shippingAddress: const AddressInput(
            firstName: 'Ada',
            lastName: 'Lovelace',
            line1: '12 Analytical Way',
            city: 'London',
            postalCode: 'EC1A',
            countryCode: 'gb',
          ),
        ),
      );

      expect(order, isA<Order>());
      expect(order.total, Money.of(4398, 'usd'));
      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaiting);
      expect(order.isPaid, isFalse);
      expect(order.shippingAddress.fullName, 'Ada Lovelace');
      expect(order.billingAddress, order.shippingAddress);
    });

    test('reads the order back, and lists it for that email', () async {
      final cart = await api.createCart();
      await api.addLine(
        cart.id,
        const AddLineRequest(variantId: 'var_small'),
      );
      final placed = await api.checkout(
        CheckoutRequest(
          cartId: cart.id,
          email: 'ada@example.com',
          shippingAddress: const AddressInput(
            firstName: 'Ada',
            lastName: 'Lovelace',
            line1: '12 Analytical Way',
            city: 'London',
            postalCode: 'EC1A',
            countryCode: 'gb',
          ),
        ),
      );

      final fetched = await api.order(placed.id, email: 'ada@example.com');
      expect(fetched.id, placed.id);
      expect(fetched.total, placed.total);

      final history = await api.orders(email: 'ada@example.com');
      expect(history.count, 1);
      expect(history.orders.single.id, placed.id);
    });
  });
}

Future<void> _seed(CommerceDatabase database) async {
  Future<void> run(String sql) =>
      queryExecute(sql, []).execute(database.executor);

  await run(
    r"INSERT INTO regions (id, name, currency_code, tax_rate, countries) "
    r"VALUES ('reg_us', 'United States', 'usd', 1000, 'us')",
  );
  await run(
    r"INSERT INTO products (id, title, handle, status) VALUES "
    r"('prod_shirt', 'T-Shirt', 't-shirt', 'published')",
  );
  await run(
    r"INSERT INTO product_variants "
    r"(id, product_id, title, inventory_quantity) VALUES "
    r"('var_small', 'prod_shirt', 'Small', 50), "
    r"('var_large', 'prod_shirt', 'Large', 20)",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999), "
    r"('var_large', 'usd', 2199), "
    r"('var_small', 'eur', 1799)",
  );
}
