import 'package:commerce_shared/src/money.dart';
import 'package:commerce_shared/src/ordering/line_item.dart';
import 'package:commerce_shared/src/ordering/shipping_method.dart';
import 'package:commerce_shared/src/region.dart';
import 'package:dust_dart/serde.dart';

part 'cart.g.dart';

/// The lines a customer has chosen, in one region's currency.
///
/// The region is part of the cart's identity rather than a lookup at
/// checkout: it fixes the currency every line must be priced in and the tax
/// rule the total is computed under. A cart that decided those at the end
/// could total differently from what it displayed all the way through.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class Cart with _$Cart {
  /// Creates a [Cart] from already-validated values.
  const Cart({
    required this.id,
    required this.region,
    required this.items,
    this.email,
    this.customerId,
    this.shippingMethod,
    this.discount,
  });

  /// Creates a [Cart], rejecting lines that do not belong in it.
  ///
  /// Throws [ArgumentError] when two lines share an id, or when a line is
  /// priced in a currency other than the region's.
  factory Cart.of({
    required String id,
    required Region region,
    List<LineItem> items = const [],
    String? email,
    String? customerId,
    ShippingMethod? shippingMethod,
    Money? discount,
  }) {
    final ids = items.map((item) => item.id).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(items, 'items', 'duplicate line id');
    }
    for (final item in items) {
      if (item.unitPrice.currencyCode != region.currencyCode) {
        throw ArgumentError.value(
          item.unitPrice.currencyCode,
          'items',
          'line ${item.id} is not priced in ${region.currencyCode}',
        );
      }
    }
    if (shippingMethod != null &&
        shippingMethod.amount.currencyCode != region.currencyCode) {
      throw ArgumentError.value(
        shippingMethod.amount.currencyCode,
        'shippingMethod',
        'shipping is not priced in ${region.currencyCode}',
      );
    }
    if (discount != null) {
      if (discount.currencyCode != region.currencyCode) {
        throw ArgumentError.value(
          discount.currencyCode,
          'discount',
          'a discount is not priced in ${region.currencyCode}',
        );
      }
      if (discount.isNegative) {
        throw ArgumentError.value(
          discount,
          'discount',
          'a negative discount is a surcharge, which this is not',
        );
      }
    }
    return Cart(
      id: id,
      region: region,
      items: items,
      email: email,
      customerId: customerId,
      shippingMethod: shippingMethod,
      discount: discount,
    );
  }

  /// Creates a [Cart] from JSON.
  factory Cart.fromJson(Map<String, Object?> json) => _$CartFromJson(json);

  /// The customer this cart belongs to, once known.
  final String? customerId;

  /// Contact address, which a guest checkout collects before an account.
  final String? email;

  /// Unique identifier.
  final String id;

  /// The chosen lines.
  final List<LineItem> items;

  /// What has been taken off, before tax. Never more than the goods.
  final Money? discount;

  /// The selling territory, fixing currency and tax.
  final Region region;

  /// How the goods are to be delivered, once chosen.
  final ShippingMethod? shippingMethod;

  /// Whether this cart holds nothing.
  bool get isEmpty => items.isEmpty;

  /// The number of units across every line, which is what a badge shows.
  int get itemCount => items.fold(0, (count, item) => count + item.quantity);

  /// The sum of every line, before tax.
  Money get subtotal => items.fold(
        Money.zero(region.currencyCode),
        (running, item) => running + item.subtotal,
      );

  /// What has actually been taken off the goods.
  ///
  /// A discount worth more than the cart holds is capped at the cart. Handing
  /// back the difference as a negative total would be paying the customer to
  /// shop, and the shipping is a cost the courier charges regardless — so a
  /// discount reduces the goods and stops there.
  Money get discountTotal {
    final asked = discount;
    if (asked == null) return Money.zero(region.currencyCode);
    return asked > subtotal ? subtotal : asked;
  }

  /// What delivery adds.
  Money get shippingTotal =>
      shippingMethod?.amount ?? Money.zero(region.currencyCode);

  /// The amount tax is worked out on: goods plus shipping, less the discount.
  ///
  /// Shipping is taxed with the goods, which is what most jurisdictions do and
  /// what Medusa does. The discount comes off before tax rather than after, so
  /// a customer is not taxed on money they did not pay.
  Money get taxableTotal => subtotal + shippingTotal - discountTotal;

  /// The tax on [taxableTotal], under the region's rule.
  Money get tax => region.taxOn(taxableTotal);

  /// What the customer pays.
  Money get total => region.withTax(taxableTotal);

  /// This cart with [line] added.
  ///
  /// A line for a variant already present merges into it, keeping the earlier
  /// line's id and price snapshot. Adding the same variant twice is one
  /// customer intending one line at a higher quantity, and the price they
  /// first saw is the one they are held to.
  Cart withLine(LineItem line) {
    final existing =
        items.where((item) => item.variantId == line.variantId).firstOrNull;
    if (existing == null) {
      return copyWith(items: [...items, line]);
    }
    final merged = existing.withQuantity(existing.quantity + line.quantity);
    return copyWith(
      items: [
        for (final item in items) item.id == existing.id ? merged : item,
      ],
    );
  }

  /// This cart without the line identified by [lineId].
  Cart withoutLine(String lineId) => copyWith(
        items: items.where((item) => item.id != lineId).toList(),
      );
}
