import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'cart.g.dart';

/// One row of `carts`, joined with the region that fixes its currency.
@Derive([ToString(), Eq(), FromRow()])
final class CartRow with _$CartRow {
  /// Creates a [CartRow].
  const CartRow({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.currencyCode,
    required this.taxRate,
    required this.taxInclusive,
    required this.countries,
    this.customerId,
    this.email,
  });

  /// The countries the region serves, comma separated.
  final String countries;

  /// The currency every line must be priced in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The account this belongs to, when there is one.
  @Sqlx(rename: 'customer_id')
  final String? customerId;

  /// Contact address for a guest checkout.
  final String? email;

  /// The primary key.
  final String id;

  /// The region's identifier.
  @Sqlx(rename: 'region_id')
  final String regionId;

  /// The region's display name.
  @Sqlx(rename: 'region_name')
  final String regionName;

  /// Whether listed prices already contain tax.
  @Sqlx(rename: 'tax_inclusive')
  final int taxInclusive;

  /// The tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int taxRate;
}

/// One row of `line_items`.
@Derive([ToString(), Eq(), FromRow()])
final class LineItemRow with _$LineItemRow {
  /// Creates a [LineItemRow].
  const LineItemRow({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.title,
    required this.unitAmount,
    required this.currencyCode,
    required this.quantity,
    this.variantTitle,
  });

  /// The currency the snapshot is in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The primary key.
  final String id;

  /// The product the line came from.
  @Sqlx(rename: 'product_id')
  final String productId;

  /// Units ordered.
  final int quantity;

  /// The product name when the line was added.
  final String title;

  /// The price of one unit when the line was added, in minor units.
  @Sqlx(rename: 'unit_amount')
  final int unitAmount;

  /// The variant being bought.
  @Sqlx(rename: 'variant_id')
  final String variantId;

  /// The variant name when the line was added.
  @Sqlx(rename: 'variant_title')
  final String? variantTitle;
}

/// One row of `regions`.
@Derive([ToString(), Eq(), FromRow()])
final class RegionRow with _$RegionRow {
  /// Creates a [RegionRow].
  const RegionRow({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.taxRate,
    required this.taxInclusive,
    required this.countries,
  });

  /// The countries served, comma separated.
  final String countries;

  /// The currency of every price in this region.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The primary key.
  final String id;

  /// Display name.
  final String name;

  /// Whether listed prices already contain tax.
  @Sqlx(rename: 'tax_inclusive')
  final int taxInclusive;

  /// The tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int taxRate;
}

/// Builds the domain [Region] a row describes.
Region regionOf({
  required String id,
  required String name,
  required String currencyCode,
  required int taxRate,
  required int taxInclusive,
  required String countries,
}) {
  return Region(
    id: id,
    name: name,
    currencyCode: currencyCode,
    taxRate: taxRate,
    taxInclusive: taxInclusive != 0,
    countries: countries.split(',').where((it) => it.isNotEmpty).toList(),
  );
}

/// Builds the domain [LineItem] a row describes.
LineItem lineOf(LineItemRow row) => LineItem(
      id: row.id,
      variantId: row.variantId,
      productId: row.productId,
      title: row.title,
      variantTitle: row.variantTitle,
      unitPrice: Money(
        amount: row.unitAmount,
        currencyCode: row.currencyCode,
      ),
      quantity: row.quantity,
    );
