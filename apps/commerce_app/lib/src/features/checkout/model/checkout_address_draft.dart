import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/derive.dart';

part 'checkout_address_draft.g.dart';

/// Editable address values retained while the customer moves between steps.
@Derive([ToString(), Eq(), CopyWith()])
final class CheckoutAddressDraft with _$CheckoutAddressDraft {
  /// Creates an address draft without treating empty form values as valid.
  const CheckoutAddressDraft({
    this.firstName = '',
    this.lastName = '',
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.countryCode = '',
    this.phone = '',
  });

  /// Town or city field value.
  final String city;

  /// Selected two-letter country code.
  final String countryCode;

  /// Given-name field value.
  final String firstName;

  /// Family-name field value.
  final String lastName;

  /// Primary street-address field value.
  final String line1;

  /// Optional apartment or company field value.
  final String line2;

  /// Optional delivery contact number.
  final String phone;

  /// Postal or ZIP code field value.
  final String postalCode;

  /// Optional state or province field value.
  final String province;

  /// Converts trimmed form values into the validated request boundary.
  AddressInput toInput() => AddressInput(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        line1: line1.trim(),
        line2: _optional(line2),
        city: city.trim(),
        province: _optional(province),
        postalCode: postalCode.trim(),
        countryCode: countryCode.trim().toLowerCase(),
        phone: _optional(phone),
      );

  static String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
