import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'model.g.dart';

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

/// Builds the domain [Product] a client sees from the rows a query returned.
///
/// This is the seam the row types exist for. A row is the table's shape; a
/// Product is the contract. Assembling here means a column rename touches this
/// function and stops, rather than travelling to the client.
Product assembleProduct(ProductRow product, List<VariantRow> variants) {
  return Product(
    id: product.id,
    title: product.title,
    handle: product.handle,
    description: product.description,
    thumbnail: product.thumbnail,
    status: _status(product.status),
    options: const [],
    variants: variants.map(assembleVariant).toList(growable: false),
  );
}

/// Builds a [ProductVariant] from a joined variant-and-price row.
///
/// SQLite has no boolean, so the flags arrive as integers and are converted
/// here rather than being exposed as ints on the domain type.
ProductVariant assembleVariant(VariantRow row) {
  return ProductVariant(
    id: row.id,
    title: row.title,
    sku: row.sku,
    prices: [Money(amount: row.amount, currencyCode: row.currencyCode)],
    inventoryQuantity: row.inventoryQuantity,
    manageInventory: row.manageInventory != 0,
    allowBackorder: row.allowBackorder != 0,
    optionValues: const {},
  );
}

/// Reads the status text a row carries.
///
/// An unknown value is treated as a draft. The catalogue queries only ever
/// select published rows, so reaching this with anything else means the
/// database holds a state this build does not know about, and the safe
/// reading of an unknown state is the one that does not sell anything.
ProductStatus _status(String stored) {
  for (final status in ProductStatus.values) {
    if (status.name == stored) return status;
  }
  return ProductStatus.draft;
}
