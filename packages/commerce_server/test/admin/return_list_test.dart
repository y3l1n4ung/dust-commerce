import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:test/test.dart';

import 'order_detail_fixture.dart';
import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async {
    harness = await AdminHarness.start(seedStore: true);
    await seedOrderDetail(harness);
    await _seedReturns(harness);
  });
  tearDown(() => harness.stop());

  test('return list requires a proven admin bearer', () async {
    (await harness.client.get('/admin/returns').send()).assertUnauthorized();
  });

  test('lists requested order returns as a bounded allowlist', () async {
    final request = harness.client.get(
      '/admin/returns?order_id=ord_detail&status=requested&limit=20&offset=0',
    )..bearer(await harness.adminToken());

    final response = await request.send();

    response.assertOk();
    final page = AdminReturnList.fromJson(
      response.json! as Map<String, Object?>,
    );
    expect(page.count, 1);
    expect(page.returns.single.id, 'ret_requested');
    expect(page.returns.single.status, AdminReturnStatus.requested);
    expect(page.returns.single.requestedAt.isUtc, isTrue);
    expect(page.returns.single.items, hasLength(2));
    expect(page.returns.single.items.last.quantity, 2);
    expect(response.body, isNot(contains('customer_id')));
    expect(response.body, isNot(contains('metadata')));
  });

  test('filters lifecycle and rejects unsupported query values', () async {
    final token = await harness.adminToken();
    final received = harness.client.get(
      '/admin/returns?order_id=ord_detail&status=received',
    )..bearer(token);

    final response = await received.send();

    response.assertOk();
    final page = AdminReturnList.fromJson(
      response.json! as Map<String, Object?>,
    );
    expect(page.returns.single.id, 'ret_received');
    expect(page.returns.single.items.single.receivedQuantity, 1);

    for (final query in ['status=open', 'order_id=bad%20id']) {
      final request = harness.client.get('/admin/returns?$query')
        ..bearer(token);
      (await request.send()).assertBadRequest();
    }
  });
}

Future<void> _seedReturns(AdminHarness harness) async {
  await harness.raw(r'''
INSERT INTO return_reasons (id, value, label)
VALUES ('reason_fit', 'fit', 'Wrong fit')
''');
  await harness.raw(r'''
INSERT INTO return_requests
  (id, display_id, order_id, customer_id, status, no_notification,
   refund_amount, requested_at, received_at, created_at, updated_at)
VALUES
  ('ret_requested', 1, 'ord_detail', 'cus_ada', 'requested', 0, NULL,
   '2026-09-11T10:00:00.000Z', NULL, '2026-09-11T10:00:00.000Z',
   '2026-09-11T10:00:00.000Z'),
  ('ret_received', 2, 'ord_detail', 'cus_ada', 'received', 1, 1500,
   '2026-09-12T10:00:00.000Z', '2026-09-13T10:00:00.000Z',
   '2026-09-12T10:00:00.000Z', '2026-09-13T10:00:00.000Z')
''');
  await harness.raw(r'''
INSERT INTO return_items
  (id, return_id, order_item_id, quantity, received_quantity,
   damaged_quantity, reason_id, note)
VALUES
  ('reti_cup', 'ret_requested', 'item_cup', 1, 0, 0, 'reason_fit', NULL),
  ('reti_shirt', 'ret_requested', 'item_shirt', 2, 0, 0, NULL, 'Too large'),
  ('reti_received', 'ret_received', 'item_cup', 1, 1, 0, NULL, NULL)
''');
}
