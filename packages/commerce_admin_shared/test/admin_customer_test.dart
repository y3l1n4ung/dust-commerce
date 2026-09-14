import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:test/test.dart';

void main() {
  test('customer page decodes explicit absence and DateTime values', () {
    final page = AdminCustomerList.fromJson({
      'customers': [
        {
          'id': 'cus_guest',
          'email': 'guest@example.com',
          'first_name': null,
          'last_name': null,
          'has_account': false,
          'created_at': '2026-09-14T01:02:03.000Z',
          'updated_at': '2026-09-14T02:03:04.000Z',
        },
      ],
      'count': 1,
      'limit': 20,
      'offset': 0,
    });

    expect(page.customers.single.email, const Some('guest@example.com'));
    expect(page.customers.single.firstName, const None<String>());
    expect(page.customers.single.lastName, const None<String>());
    expect(page.customers.single.createdAt.isUtc, isTrue);
  });

  test('customer ordering accepts only the Medusa table allowlist', () {
    expect(
      AdminCustomerOrder.parse('-has_account'),
      const Some(AdminCustomerOrder.hasAccountDesc),
    );
    expect(AdminCustomerOrder.parse('metadata'), const None());
  });
}
