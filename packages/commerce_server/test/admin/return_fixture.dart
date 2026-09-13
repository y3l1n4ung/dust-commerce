import 'support.dart';

/// Inserts requested and received returns for the shared Admin order fixture.
Future<void> seedAdminReturns(AdminHarness harness) async {
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
