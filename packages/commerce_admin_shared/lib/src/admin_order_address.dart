import 'package:commerce_admin_shared/src/admin_option.dart';
import 'package:dust_dart/serde.dart';

part 'admin_order_address.g.dart';

/// Postal address frozen when an order was placed.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminOrderAddress with _$AdminOrderAddress {
  /// Creates a merchant-visible address without persistence fields.
  const AdminOrderAddress({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.line1,
    required this.line2,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.countryCode,
    required this.phone,
  });

  /// Decodes one generated Admin address response.
  factory AdminOrderAddress.fromJson(Map<String, Object?> json) =>
      _$AdminOrderAddressFromJson(json);

  /// Town or city captured at checkout.
  final String city;

  /// Optional company distinct from the secondary street line.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> company;

  /// Lowercase ISO 3166-1 alpha-2 country code.
  final String countryCode;

  /// Recipient given name.
  final String firstName;

  /// Recipient family name.
  final String lastName;

  /// Primary street line.
  final String line1;

  /// Optional apartment, suite, or unit.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> line2;

  /// Optional courier contact number.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> phone;

  /// Postal or ZIP code.
  final String postalCode;

  /// Optional state, province, or region.
  @SerDe(using: AdminOptionalStringCodec())
  final Option<String> province;
}
