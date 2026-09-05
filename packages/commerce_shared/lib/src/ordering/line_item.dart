import 'package:commerce_shared/src/catalog/variant.dart';
import 'package:commerce_shared/src/money.dart';
import 'package:dust_dart/serde.dart';

part 'line_item.g.dart';

/// One variant, at one quantity, at the price it was added for.
///
/// The unit price is a snapshot, not a reference. A cart that reads today's
/// price when it renders would silently rewrite what someone agreed to when
/// they added the item, and the first they would know is the total moving
/// between two page loads.
///
/// The titles are copied for the same reason: an item renamed after it was
/// added should still show, in the cart, the name it was added under.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
class LineItem with _$LineItem {
  /// Creates a [LineItem] from already-validated values.
  const LineItem({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.variantTitle,
  });

  /// Creates a [LineItem], rejecting a quantity below one or a negative price.
  factory LineItem.of({
    required String id,
    required String variantId,
    required String productId,
    required String title,
    required Money unitPrice,
    required int quantity,
    String? variantTitle,
  }) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'expected at least one');
    }
    if (unitPrice.isNegative) {
      throw ArgumentError.value(
        unitPrice,
        'unitPrice',
        'a line cannot cost less than nothing',
      );
    }
    return LineItem(
      id: id,
      variantId: variantId,
      productId: productId,
      title: title,
      variantTitle: variantTitle,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }

  /// Creates a [LineItem] by taking a price snapshot from [variant].
  ///
  /// Throws [ArgumentError] when the variant has no price in [currencyCode] —
  /// a variant that is not sold in the cart's currency cannot enter it.
  factory LineItem.fromVariant({
    required String id,
    required String productId,
    required String productTitle,
    required ProductVariant variant,
    required String currencyCode,
    required int quantity,
  }) {
    final price = variant.priceIn(currencyCode);
    if (price == null) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'variant ${variant.id} has no price in this currency',
      );
    }
    return LineItem.of(
      id: id,
      variantId: variant.id,
      productId: productId,
      title: productTitle,
      variantTitle: variant.title,
      unitPrice: price,
      quantity: quantity,
    );
  }

  /// Creates a [LineItem] from JSON.
  factory LineItem.fromJson(Map<String, Object?> json) =>
      _$LineItemFromJson(json);

  /// Unique identifier.
  final String id;

  /// The product this line came from.
  final String productId;

  /// Units ordered.
  final int quantity;

  /// The product name at the time of adding.
  final String title;

  /// The price of one unit at the time of adding.
  final Money unitPrice;

  /// The variant being bought.
  final String variantId;

  /// The variant name at the time of adding.
  final String? variantTitle;

  /// The price of this line: [unitPrice] times [quantity].
  Money get subtotal => unitPrice * quantity;

  /// This line at [quantity], keeping the original price snapshot.
  LineItem withQuantity(int quantity) => LineItem.of(
        id: id,
        variantId: variantId,
        productId: productId,
        title: title,
        variantTitle: variantTitle,
        unitPrice: unitPrice,
        quantity: quantity,
      );
}
