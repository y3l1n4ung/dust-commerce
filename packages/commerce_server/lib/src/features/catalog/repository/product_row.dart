import 'package:dust_dart/db.dart';

part 'product_row.g.dart';

/// One row of `products`.
///
/// Deliberately not the shared `Product`. A row is the shape the table has —
/// flat, nullable where the column is, with the status as the text SQLite
/// stores. The domain type is assembled from several of these, and keeping
/// them apart is what stops a column rename reaching the client.
@Derive([ToString(), Eq(), FromRow()])
final class ProductRow with _$ProductRow {
  /// Creates a [ProductRow].
  const ProductRow({
    required this.id,
    required this.title,
    required this.handle,
    required this.status,
    this.description,
    this.thumbnail,
  });

  /// Long-form copy.
  final String? description;

  /// URL-safe identifier.
  final String handle;

  /// The primary key.
  final String id;

  /// Publishing state, as stored.
  final String status;

  /// Primary image.
  final String? thumbnail;

  /// Display name.
  final String title;
}

/// One row of `product_variants`, joined with its price in one currency.
///
/// The price is joined rather than fetched separately because a variant
/// without a price in the requested currency is not sellable there, and a
/// query that returns it anyway pushes that decision into Dart.
@Derive([ToString(), Eq(), FromRow()])
final class VariantRow with _$VariantRow {
  /// Creates a [VariantRow].
  const VariantRow({
    required this.id,
    required this.productId,
    required this.title,
    required this.inventoryQuantity,
    required this.manageInventory,
    required this.allowBackorder,
    required this.currencyCode,
    required this.amount,
    this.sku,
  });

  /// Whether this variant sells past its stock.
  @Sqlx(rename: 'allow_backorder')
  final int allowBackorder;

  /// The price in [currencyCode], in minor units.
  final int amount;

  /// The currency the price is in.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// The primary key.
  final String id;

  /// Units on hand.
  @Sqlx(rename: 'inventory_quantity')
  final int inventoryQuantity;

  /// Whether stock is tracked.
  @Sqlx(rename: 'manage_inventory')
  final int manageInventory;

  /// The product this belongs to.
  @Sqlx(rename: 'product_id')
  final String productId;

  /// Stock keeping unit.
  final String? sku;

  /// Display name.
  final String title;
}
