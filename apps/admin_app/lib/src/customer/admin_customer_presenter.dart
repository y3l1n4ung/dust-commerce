import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:intl/intl.dart';

/// Medusa's label for a customer credential state.
String adminCustomerAccount(AdminCustomer customer) =>
    customer.hasAccount ? 'Registered' : 'Guest';

/// Customer email or Medusa's visible missing-value placeholder.
String adminCustomerEmail(AdminCustomer customer) => customer.email.match(
      some: (value) => value,
      none: () => '—',
    );

/// Joins only supplied name parts without exposing nullable wire fields.
String adminCustomerName(AdminCustomer customer) {
  final parts = [
    customer.firstName.match(some: (value) => value, none: () => ''),
    customer.lastName.match(some: (value) => value, none: () => ''),
  ].where((value) => value.isNotEmpty);
  return parts.isEmpty ? '—' : parts.join(' ');
}

/// Compact local date shown in the customer table.
String adminCustomerCreated(DateTime value) =>
    DateFormat.yMMMd().format(value.toLocal());

/// Full local instant exposed as the date-cell tooltip.
String adminCustomerCreatedFull(DateTime value) =>
    DateFormat.yMMMd().add_jm().format(value.toLocal());
