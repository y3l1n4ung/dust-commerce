import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'shipping.g.dart';

/// One row of `shipping_options`: what a region offers.
@Derive([ToString(), Eq(), FromRow()])
final class ShippingOptionRow with _$ShippingOptionRow {
  /// Creates a [ShippingOptionRow].
  const ShippingOptionRow({
    required this.id,
    required this.regionId,
    required this.name,
    required this.amount,
    required this.currencyCode,
  });

  /// What it costs, in minor units.
  final int amount;

  /// The currency that amount is in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The primary key.
  final String id;

  /// The service name shown to a customer.
  final String name;

  /// The region that offers it.
  @Sqlx(rename: 'region_id')
  final String regionId;
}

/// One row of `cart_shipping_methods`: what a cart chose.
@Derive([ToString(), Eq(), FromRow()])
final class ShippingMethodRow with _$ShippingMethodRow {
  /// Creates a [ShippingMethodRow].
  const ShippingMethodRow({
    required this.optionId,
    required this.name,
    required this.amount,
  });

  /// The price snapshotted when it was chosen.
  final int amount;

  /// The service name at the time of choosing.
  final String name;

  /// The option it came from.
  @Sqlx(rename: 'option_id')
  final String optionId;
}

/// Builds the domain [ShippingMethod] a row describes.
ShippingMethod methodOf(ShippingMethodRow row, String currencyCode) =>
    ShippingMethod(
      optionId: row.optionId,
      name: row.name,
      amount: Money(amount: row.amount, currencyCode: currencyCode),
    );
