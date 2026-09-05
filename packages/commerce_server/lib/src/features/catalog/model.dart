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

/// One row of `product_options`.
///
/// The permitted values are stored as one comma-separated column rather than a
/// child table. An option's values are read and written together, never
/// queried individually, so a join would buy nothing and cost a table.
@Derive([ToString(), Eq(), FromRow()])
final class ProductOptionRow with _$ProductOptionRow {
  /// Creates a [ProductOptionRow].
  const ProductOptionRow({
    required this.id,
    required this.productId,
    required this.title,
    required this.valuesCsv,
  });

  /// The primary key.
  final String id;

  /// The product this option belongs to.
  @Sqlx(rename: 'product_id')
  final String productId;

  /// Display name, such as `Size`.
  final String title;

  /// The permitted values, comma separated.
  @Sqlx(rename: 'values_csv')
  final String valuesCsv;
}

/// One row of `variant_option_values`: the value a variant chose.
@Derive([ToString(), Eq(), FromRow()])
final class VariantOptionValueRow with _$VariantOptionValueRow {
  /// Creates a [VariantOptionValueRow].
  const VariantOptionValueRow({
    required this.variantId,
    required this.optionId,
    required this.value,
  });

  /// The option this value answers.
  @Sqlx(rename: 'option_id')
  final String optionId;

  /// The chosen value.
  final String value;

  /// The variant that chose it.
  @Sqlx(rename: 'variant_id')
  final String variantId;
}

/// Builds the domain [Product] a client sees from the rows a query returned.
///
/// This is the seam the row types exist for. A row is the table's shape; a
/// Product is the contract. Assembling here means a column rename touches this
/// function and stops, rather than travelling to the client.
Product assembleProduct(
  ProductRow product,
  List<VariantRow> variants, {
  List<ProductOptionRow> options = const [],
  List<VariantOptionValueRow> optionValues = const [],
}) {
  return Product(
    id: product.id,
    title: product.title,
    handle: product.handle,
    description: product.description,
    thumbnail: product.thumbnail,
    status: _status(product.status),
    options: options.map(assembleOption).toList(growable: false),
    variants: [
      for (final variant in variants)
        assembleVariant(
          variant,
          optionValues: {
            for (final chosen in optionValues)
              if (chosen.variantId == variant.id) chosen.optionId: chosen.value,
          },
        ),
    ],
  );
}

/// Builds a [ProductVariant] from a joined variant-and-price row.
///
/// SQLite has no boolean, so the flags arrive as integers and are converted
/// here rather than being exposed as ints on the domain type.
ProductVariant assembleVariant(
  VariantRow row, {
  Map<String, String> optionValues = const {},
}) {
  return ProductVariant(
    id: row.id,
    title: row.title,
    sku: row.sku,
    prices: [Money(amount: row.amount, currencyCode: row.currencyCode)],
    inventoryQuantity: row.inventoryQuantity,
    manageInventory: row.manageInventory != 0,
    allowBackorder: row.allowBackorder != 0,
    optionValues: optionValues,
  );
}

/// Builds the domain [ProductOption] a row describes.
///
/// An empty value is dropped rather than kept: a trailing comma in the column
/// would otherwise become an option a storefront renders as a blank choice.
ProductOption assembleOption(ProductOptionRow row) {
  return ProductOption(
    id: row.id,
    title: row.title,
    values: row.valuesCsv.split(',').where((it) => it.isNotEmpty).toList(),
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
