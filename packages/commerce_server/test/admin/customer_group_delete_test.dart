import 'package:test/test.dart';

import 'customer_group_list_test_support.dart';
import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async {
    harness = await AdminHarness.start();
    await seedCustomerGroupList(harness);
  });
  tearDown(() => harness.stop());

  test('customer-group deletion requires the Admin route guard', () async {
    final response =
        await harness.client.delete('/admin/customer-groups/cusgrp_vip').send();

    response.assertUnauthorized();
  });

  test('retires the group and memberships without deleting customers',
      () async {
    final token = await harness.adminToken();
    final response = await (harness.client.delete(
      '/admin/customer-groups/cusgrp_vip',
    )..bearer(token))
        .send();

    response.assertOk();
    expect(response.json, {
      'id': 'cusgrp_vip',
      'object': 'customer_group',
      'deleted': true,
    });
    (await (harness.client.get('/admin/customer-groups/cusgrp_vip')
              ..bearer(token))
            .send())
        .assertNotFound();

    final group = await harness.raw(r'''
SELECT deleted_at, updated_at FROM customer_groups WHERE id = 'cusgrp_vip'
''');
    final deletedAt = group.single.readIndexNullable<String>(0);
    expect(deletedAt, isNotNull);
    expect(DateTime.parse(deletedAt!).isUtc, isTrue);
    expect(group.single.readIndex<String>(1), deletedAt);

    final memberships = await harness.raw(r'''
SELECT count(*), count(deleted_at)
FROM customer_group_customers WHERE customer_group_id = 'cusgrp_vip'
''');
    expect(memberships.single.readIndex<int>(0), 3);
    expect(memberships.single.readIndex<int>(1), 3);
    final customers = await harness.raw(r'''
SELECT count(*) FROM customers WHERE id IN ('cus_ada', 'cus_guest')
  AND deleted_at IS NULL
''');
    expect(customers.single.readIndex<int>(0), 2);
  });

  test('missing, retired, and repeatedly deleted groups are not found',
      () async {
    final token = await harness.adminToken();
    for (final id in ['cusgrp_missing', 'cusgrp_retired']) {
      final request = harness.client.delete('/admin/customer-groups/$id')
        ..bearer(token);
      (await request.send()).assertNotFound();
    }

    final first = harness.client.delete('/admin/customer-groups/cusgrp_vip')
      ..bearer(token);
    (await first.send()).assertOk();
    final repeated = harness.client.delete('/admin/customer-groups/cusgrp_vip')
      ..bearer(token);
    (await repeated.send()).assertNotFound();
  });

  test('membership failure rolls back the group deletion', () async {
    await harness.raw(r'''
CREATE TRIGGER reject_customer_group_membership_retirement
BEFORE UPDATE OF deleted_at ON customer_group_customers
WHEN NEW.customer_group_id = 'cusgrp_vip'
BEGIN
  SELECT RAISE(ABORT, 'membership retirement failed');
END
''');
    final request = harness.client.delete('/admin/customer-groups/cusgrp_vip')
      ..bearer(await harness.adminToken());

    (await request.send()).assertStatus(500);
    final group = await harness.raw(r'''
SELECT deleted_at FROM customer_groups WHERE id = 'cusgrp_vip'
''');
    expect(group.single.readIndexNullable<String>(0), isNull);
    final activeMemberships = await harness.raw(r'''
SELECT count(*) FROM customer_group_customers
WHERE customer_group_id = 'cusgrp_vip' AND deleted_at IS NULL
''');
    expect(activeMemberships.single.readIndex<int>(0), 3);
  });
}
