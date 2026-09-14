import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/testing.dart';

import '../checkout/support.dart';

final class ReturnScenario {
  ReturnScenario._(this.harness);

  static Future<ReturnScenario> start() async {
    final harness = await CheckoutHarness.start();
    await queryExecute(
      "INSERT INTO return_reasons (id, value, label) VALUES "
      "('reason_damaged', 'damaged', 'Damaged')",
      const [],
    ).execute(harness.database.executor);
    return ReturnScenario._(harness);
  }

  final CheckoutHarness harness;

  TestClient get client => harness.client;

  Future<void> stop() => harness.stop();

  Future<({Order order, String token})> order({
    bool complete = true,
    String email = 'owner@example.com',
  }) async {
    final account = await harness.account(email);
    final cart = await harness.cartWith(
      'var_small',
      quantity: 3,
      token: account.token,
    );
    final placed = await harness.checkout(cart, token: account.token);
    placed.assertCreated();
    var order = Order.fromJson(placed.json! as Map<String, Object?>);
    if (complete) {
      final authorize = client.post('/store/orders/${order.id}/payments')
        ..bearer(account.token);
      (await authorize.send()).assertCreated();
      final capture = client.post('/store/orders/${order.id}/payments/capture')
        ..bearer(account.token);
      final captured = await capture.send();
      captured.assertOk();
      // Completion is independent from payment capture; model that Admin
      // transition explicitly until the dedicated completion slice lands.
      await queryExecute(
        "UPDATE orders SET status = 'completed' WHERE id = ?",
        [order.id],
      ).execute(harness.database.executor);
      final read = client.get('/store/orders/${order.id}')
        ..bearer(account.token);
      final refreshed = await read.send();
      refreshed.assertOk();
      order = Order.fromJson(refreshed.json! as Map<String, Object?>);
    }
    return (order: order, token: account.token);
  }

  TestRequest request(
    Order order,
    String token, {
    String? itemId,
    int quantity = 1,
    String? reasonId = 'reason_damaged',
  }) {
    final request = client.post('/store/returns')
      ..bearer(token)
      ..json({
        'order_id': order.id,
        'items': [
          {
            'id': itemId ?? order.items.single.id,
            'quantity': quantity,
            if (reasonId != null) 'reason_id': reasonId,
          },
        ],
        'note': 'Please inspect the damaged item',
      });
    return request;
  }
}
