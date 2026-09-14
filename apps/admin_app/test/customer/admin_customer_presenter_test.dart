import 'package:admin_app/src/customer/admin_customer_presenter.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presents only the supplied customer name parts', () {
    expect(adminCustomerName(_customer(first: 'Ada', last: 'Lovelace')),
        'Ada Lovelace');
    expect(adminCustomerName(_customer(first: 'Ada')), 'Ada');
    expect(adminCustomerName(_customer(last: 'Lovelace')), 'Lovelace');
    expect(adminCustomerName(_customer()), '—');
  });

  test('presents account state with Medusa labels', () {
    expect(adminCustomerAccount(_customer(hasAccount: true)), 'Registered');
    expect(adminCustomerAccount(_customer()), 'Guest');
  });
}

AdminCustomer _customer({
  String? first,
  String? last,
  bool hasAccount = false,
}) =>
    AdminCustomer(
      id: 'cus_test',
      emailValue: null,
      firstNameValue: first,
      lastNameValue: last,
      hasAccount: hasAccount,
      createdAt: DateTime.utc(2026, 9, 14),
      updatedAt: DateTime.utc(2026, 9, 14),
    );
