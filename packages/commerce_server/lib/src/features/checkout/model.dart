import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'model.g.dart';

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

/// Builds the domain [Address] a row describes.
Address addressOf(OrderAddressRow row) => Address(
      firstName: row.firstName,
      lastName: row.lastName,
      line1: row.line1,
      line2: row.line2,
      city: row.city,
      province: row.province,
      postalCode: row.postalCode,
      countryCode: row.countryCode,
      phone: row.phone,
    );

/// Assembles the domain [Order] from a header row, its lines and addresses.
///
/// The totals come from the header, not from re-adding the lines. They were
/// frozen when the order was placed, and recomputing them here would quietly
/// undo that the first time a tax rate changed.
Order orderOf(
  OrderRow row,
  List<LineItemRow> items,
  List<OrderAddressRow> addresses,
) {
  final shipping = addresses.where((it) => it.kind == 'shipping').first;
  final billing =
      addresses.where((it) => it.kind == 'billing').firstOrNull ?? shipping;

  return Order(
    id: row.id,
    email: row.email,
    customerId: row.customerId,
    region: regionOf(
      id: row.regionId,
      name: row.regionName,
      currencyCode: row.currencyCode,
      taxRate: row.taxRate,
      taxInclusive: row.taxInclusive,
      countries: row.countries,
    ),
    items: items.map(lineOf).toList(growable: false),
    subtotal: Money(amount: row.subtotal, currencyCode: row.currencyCode),
    tax: Money(amount: row.tax, currencyCode: row.currencyCode),
    total: Money(amount: row.total, currencyCode: row.currencyCode),
    shippingAddress: addressOf(shipping),
    billingAddress: addressOf(billing),
    placedAt: DateTime.parse(row.placedAt),
    status: _orderStatus(row.status),
    paymentStatus: _paymentStatus(row.paymentStatus),
  );
}

OrderStatus _orderStatus(String stored) {
  for (final status in OrderStatus.values) {
    if (status.name == stored) return status;
  }
  return OrderStatus.pending;
}

PaymentStatus _paymentStatus(String stored) {
  for (final status in PaymentStatus.values) {
    if (status.name == stored) return status;
  }
  return PaymentStatus.awaiting;
}
