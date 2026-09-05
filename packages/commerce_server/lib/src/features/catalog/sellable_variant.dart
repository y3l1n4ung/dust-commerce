import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'sellable_variant.g.dart';

/// One sellable variant plus the product snapshots a cart line needs.
@Derive([ToString(), Eq(), FromRow()])
final class SellableVariantRow with _$SellableVariantRow {
  /// Creates a [SellableVariantRow].
  const SellableVariantRow({
    required this.id,
    required this.productId,
    required this.productHandle,
    required this.productTitle,
    required this.title,
    required this.inventoryQuantity,
    required this.manageInventory,
    required this.allowBackorder,
    required this.currencyCode,
    required this.amount,
    this.sku,
    this.thumbnail,
  });

  /// Whether sales may exceed tracked stock.
  @Sqlx(rename: 'allow_backorder')
  final int allowBackorder;

  /// Price in integer minor units.
  final int amount;

  /// Currency for [amount].
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// Variant identifier.
  final String id;

  /// Units currently available.
  @Sqlx(rename: 'inventory_quantity')
  final int inventoryQuantity;

  /// Whether stock is tracked.
  @Sqlx(rename: 'manage_inventory')
  final int manageInventory;

  /// Stable customer-facing product route.
  @Sqlx(rename: 'product_handle')
  final String productHandle;

  /// Product identifier.
  @Sqlx(rename: 'product_id')
  final String productId;

  /// Customer-facing product name.
  @Sqlx(rename: 'product_title')
  final String productTitle;

  /// Stock keeping unit.
  final String? sku;

  /// Primary product image.
  final String? thumbnail;

  /// Customer-facing variant name.
  final String title;
}

/// Builds the stock behavior shared by add and quantity operations.
ProductVariant assembleSellableVariant(SellableVariantRow row) =>
    ProductVariant(
      id: row.id,
      title: row.title,
      sku: row.sku,
      prices: [Money(amount: row.amount, currencyCode: row.currencyCode)],
      inventoryQuantity: row.inventoryQuantity,
      manageInventory: row.manageInventory != 0,
      allowBackorder: row.allowBackorder != 0,
      optionValues: const {},
    );
