import 'dart:convert';

import 'package:commerce_server/src/features/cart/model/shipping.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'cart.g.dart';
part 'cart_totals.dart';

/// Explicit cart response populated directly from the cart-and-region query.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class CartResponse with _$CartResponse {
  /// Creates an allowlisted cart response.
  const CartResponse({
    required this.id,
    required this.region,
    this.items = const [],
    this.customerId,
    this.email,
    this.shippingMethod,
    this.discount,
    this.promotionCode,
  });

  /// Customer owner once this guest cart is claimed.
  @Sqlx(rename: 'customer_id')
  final String? customerId;

  /// Discount currently applied to the goods.
  @Sqlx(tryFrom: OptionalMoneyFromJson())
  final Money? discount;

  /// Guest or customer contact email stored on the cart.
  final String? email;

  /// Stable cart identifier.
  final String id;

  /// Explicit line-item responses.
  @Sqlx(tryFrom: LineItemsFromJson())
  final List<LineItemResponse> items;

  /// Applied promotion code snapshot.
  @Sqlx(rename: 'promotion_code')
  final String? promotionCode;

  /// Explicit selling-region response.
  @Sqlx(tryFrom: RegionResponseFromJson())
  final RegionResponse region;

  /// Explicit selected delivery response.
  @Sqlx(
    rename: 'shipping_method',
    tryFrom: OptionalShippingMethodFromJson(),
  )
  final ShippingMethodResponse? shippingMethod;
}

/// Explicit line-item response populated directly by SQLx.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class LineItemResponse with _$LineItemResponse {
  /// Creates an allowlisted line-item response.
  const LineItemResponse({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productHandle,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.variantTitle,
    this.thumbnail,
  });

  /// Stable line identifier.
  final String id;

  /// Product route captured when the line was added.
  @Sqlx(rename: 'product_handle')
  final String productHandle;

  /// Product identifier captured when the line was added.
  @Sqlx(rename: 'product_id')
  final String productId;

  /// Quantity currently requested.
  final int quantity;

  /// Product image captured when the line was added.
  final String? thumbnail;

  /// Product title captured when the line was added.
  final String title;

  /// Price snapshot for one unit.
  @Sqlx(rename: 'unit_price', tryFrom: MoneyFromJson())
  final Money unitPrice;

  /// Variant identifier used for stock checks.
  @Sqlx(rename: 'variant_id')
  final String variantId;

  /// Variant title captured when the line was added.
  @Sqlx(rename: 'variant_title')
  final String? variantTitle;
}

/// Explicit selling-region response.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class RegionResponse with _$RegionResponse {
  /// Creates an allowlisted selling region.
  const RegionResponse({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.taxRate,
    required this.countries,
    required this.taxInclusive,
  });

  /// ISO country codes served by this region.
  @Sqlx(tryFrom: CountriesFromCsv())
  final List<String> countries;

  /// Currency used by every regional amount.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// Stable region identifier.
  final String id;

  /// Customer-facing region name.
  final String name;

  /// Whether displayed amounts already contain tax.
  @Sqlx(rename: 'tax_inclusive', tryFrom: BoolFromInt())
  final bool taxInclusive;

  /// Tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int taxRate;
}

/// Converts SQLite's integer boolean representation.
final class BoolFromInt implements SqlxTryFrom<bool, int> {
  /// Creates the stateless converter.
  const BoolFromInt();

  @override
  bool decode(int value) => value != 0;
}

/// Converts the compact region country list.
final class CountriesFromCsv implements SqlxTryFrom<List<String>, String> {
  /// Creates the stateless converter.
  const CountriesFromCsv();

  @override
  List<String> decode(String value) => value
      .split(',')
      .where((country) => country.isNotEmpty)
      .toList(growable: false);
}

/// Builds [Money] from a JSON object selected by SQLite.
final class MoneyFromJson implements SqlxTryFrom<Money, String> {
  /// Creates the stateless converter.
  const MoneyFromJson();

  @override
  Money decode(String value) => Money.fromJson(_object(value));
}

/// Builds explicit line responses from a SQLite JSON aggregate.
final class LineItemsFromJson
    implements SqlxTryFrom<List<LineItemResponse>, String> {
  /// Creates the stateless converter.
  const LineItemsFromJson();

  @override
  List<LineItemResponse> decode(String value) => [
        for (final item in jsonDecode(value) as List<Object?>)
          decodeItem(item! as Map<String, Object?>),
      ];

  /// Decodes one line object reused by immutable order snapshots.
  static LineItemResponse decodeItem(Map<String, Object?> item) =>
      LineItemResponse(
        id: item['id']! as String,
        variantId: item['variant_id']! as String,
        productId: item['product_id']! as String,
        productHandle: item['product_handle']! as String,
        title: item['title']! as String,
        variantTitle: item['variant_title'] as String?,
        thumbnail: item['thumbnail'] as String?,
        unitPrice: Money.fromJson(
          item['unit_price']! as Map<String, Object?>,
        ),
        quantity: item['quantity']! as int,
      );
}

/// Decodes an optional discount without using null outside the response field.
final class OptionalMoneyFromJson implements SqlxTryFrom<Money?, String> {
  /// Creates the stateless converter.
  const OptionalMoneyFromJson();

  @override
  Money? decode(String value) =>
      value == 'null' ? null : Money.fromJson(_object(value));
}

/// Decodes an optional explicit shipping-method response.
final class OptionalShippingMethodFromJson
    implements SqlxTryFrom<ShippingMethodResponse?, String> {
  /// Creates the stateless converter.
  const OptionalShippingMethodFromJson();

  @override
  ShippingMethodResponse? decode(String value) {
    if (value == 'null') return null;
    final json = _object(value);
    return ShippingMethodResponse(
      optionId: json['option_id']! as String,
      name: json['name']! as String,
      amount: Money.fromJson(json['amount']! as Map<String, Object?>),
    );
  }
}

/// Builds an explicit region response from a JSON object selected by SQLite.
final class RegionResponseFromJson
    implements SqlxTryFrom<RegionResponse, String> {
  /// Creates the stateless converter.
  const RegionResponseFromJson();

  @override
  RegionResponse decode(String value) {
    final json = _object(value);
    return RegionResponse(
      id: json['id']! as String,
      name: json['name']! as String,
      currencyCode: json['currency_code']! as String,
      taxRate: json['tax_rate']! as int,
      countries: (json['countries']! as String)
          .split(',')
          .where((country) => country.isNotEmpty)
          .toList(growable: false),
      taxInclusive: json['tax_inclusive']! as int != 0,
    );
  }
}

Map<String, Object?> _object(String value) =>
    jsonDecode(value) as Map<String, Object?>;
