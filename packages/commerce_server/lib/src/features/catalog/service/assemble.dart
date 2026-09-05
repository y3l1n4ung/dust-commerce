import 'package:commerce_server/src/features/catalog/repository/product_row.dart';
import 'package:commerce_shared/commerce_shared.dart';

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
