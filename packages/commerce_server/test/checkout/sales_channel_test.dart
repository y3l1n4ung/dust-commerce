import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late CheckoutHarness harness;

  setUp(() async => harness = await CheckoutHarness.start());
  tearDown(() async => harness.stop());

  test('checkout snapshots the cart sales channel onto the order', () async {
    await queryExecute(
      r"INSERT INTO sales_channels (id, name) VALUES ('sc_web', 'Online Store')",
      const [],
    ).execute(harness.database.executor);

    final cartId = await harness.cartWith('var_small');
    final cartChannel = await queryRaw(
      'SELECT sales_channel_id FROM cart_sales_channels WHERE cart_id = ?',
      [cartId],
    ).fetch(harness.database.connection as Executor);
    expect(cartChannel.single.readIndex<String>(0), 'sc_web');

    (await harness.checkout(cartId)).assertCreated();
    final orderChannel = await queryRaw(
      'SELECT link.sales_channel_id FROM order_sales_channels link '
      'JOIN orders placed ON placed.id = link.order_id '
      'WHERE placed.cart_id = ?',
      [cartId],
    ).fetch(harness.database.connection as Executor);
    expect(orderChannel.single.readIndex<String>(0), 'sc_web');
  });
}
