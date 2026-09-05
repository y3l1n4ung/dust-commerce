import 'package:dust_dart/db.dart';

part 'order_row.g.dart';

/// One row of `orders`, joined with the region it was sold under.
@Derive([ToString(), Eq(), FromRow()])
final class OrderRow with _$OrderRow {
  /// Creates an [OrderRow].
  const OrderRow({
    required this.id,
    required this.email,
    required this.currencyCode,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.placedAt,
    required this.regionId,
    required this.regionName,
    required this.taxRate,
    required this.taxInclusive,
    required this.countries,
    this.customerId,
  });

  /// The countries the region serves, comma separated.
  final String countries;

  /// The currency every amount is in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The account that placed this, when there was one.
  @Sqlx(rename: 'customer_id')
  final String? customerId;

  /// Contact address for the buyer.
  final String email;

  /// The primary key.
  final String id;

  /// Whether the money has moved.
  @Sqlx(rename: 'payment_status')
  final String paymentStatus;

  /// When this was placed, ISO-8601.
  @Sqlx(rename: 'placed_at')
  final String placedAt;

  /// The region's identifier.
  @Sqlx(rename: 'region_id')
  final String regionId;

  /// The region's display name.
  @Sqlx(rename: 'region_name')
  final String regionName;

  /// Lifecycle state.
  final String status;

  /// The frozen sum of the lines, before tax.
  final int subtotal;

  /// The frozen tax.
  final int tax;

  /// Whether the region's prices already contained tax.
  @Sqlx(rename: 'tax_inclusive')
  final int taxInclusive;

  /// The region's tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int taxRate;

  /// The frozen amount charged.
  final int total;
}

/// One row of `order_addresses`.
@Derive([ToString(), Eq(), FromRow()])
final class OrderAddressRow with _$OrderAddressRow {
  /// Creates an [OrderAddressRow].
  const OrderAddressRow({
    required this.kind,
    required this.firstName,
    required this.lastName,
    required this.line1,
    required this.city,
    required this.postalCode,
    required this.countryCode,
    this.line2,
    this.province,
    this.phone,
  });

  /// Town or city.
  final String city;

  /// ISO 3166-1 alpha-2 country code.
  @Sqlx(rename: 'country_code')
  final String countryCode;

  /// Given name.
  @Sqlx(rename: 'first_name')
  final String firstName;

  /// Whether this is the shipping or the billing address.
  final String kind;

  /// Family name.
  @Sqlx(rename: 'last_name')
  final String lastName;

  /// Street address.
  final String line1;

  /// Apartment, suite, or similar.
  final String? line2;

  /// Contact number.
  final String? phone;

  /// Postal or ZIP code.
  @Sqlx(rename: 'postal_code')
  final String postalCode;

  /// State, province, or region.
  final String? province;
}
