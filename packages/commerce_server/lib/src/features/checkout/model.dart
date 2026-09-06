import 'dart:convert';

import 'package:commerce_server/src/features/cart/model/model.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'model.g.dart';

/// Explicit public payment receipt; provider metadata never crosses the API.
final class OrderPaymentResponse implements Serializable {
  /// Creates a safe payment receipt from persisted provider facts.
  const OrderPaymentResponse({
    required this.providerId,
    required this.amount,
    required this.createdAt,
  });

  /// Amount authorised against the frozen order total.
  final Money amount;

  /// When this provider payment record was created.
  final DateTime createdAt;

  /// Public adapter identifier used by the storefront display map.
  final String providerId;

  @override
  Map<String, Object?> serialize() => <String, Object?>{
        'provider_id': providerId,
        'amount': amount,
        'created_at': createdAt,
      };

  @override
  Map<String, Object?> toJson() => serialize();
}

/// Complete order response populated directly by one SQLx query.
///
/// Serialization is an explicit allowlist. This class does not inherit the
/// domain order, so new internal order fields cannot appear on the wire.
@Derive([FromRow()])
final class OrderResponse implements Serializable {
  /// Constructs the final response directly from frozen database values.
  OrderResponse({
    required this.orderId,
    required this.displayId,
    required this.orderEmail,
    required this.currencyCode,
    required this.orderSubtotal,
    required this.orderShippingTotal,
    required this.orderDiscountTotal,
    required this.orderTax,
    required this.orderTotal,
    required this.storedStatus,
    required this.storedPaymentStatus,
    required this.placedAtText,
    required this.regionId,
    required this.regionName,
    required this.regionTaxRate,
    required this.regionTaxInclusive,
    required this.regionCountries,
    required this.itemsJson,
    required this.shippingAddressJson,
    required this.billingAddressJson,
    this.orderCustomerId,
    this.paymentAmount,
    this.paymentCreatedAtText,
    this.paymentProvider,
    this.shippingOptionId,
    this.shippingName,
  });

  /// Billing address encoded by SQLite's JSON functions.
  @Sqlx(rename: 'billing_address_json')
  final String billingAddressJson;

  /// Currency shared by every frozen monetary amount.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// Immutable order lines encoded as one JSON array.
  @Sqlx(rename: 'items_json')
  final String itemsJson;

  /// Customer owner when the order was not placed as a guest.
  @Sqlx(rename: 'customer_id')
  final String? orderCustomerId;

  /// Contact email captured at checkout.
  @Sqlx(rename: 'email')
  final String orderEmail;

  /// Short monotonically increasing identifier shown to people.
  @Sqlx(rename: 'display_id')
  final int displayId;

  /// Stable order identifier.
  @Sqlx(rename: 'id')
  final String orderId;

  /// Authorised payment amount, absent before payment begins.
  @Sqlx(rename: 'payment_amount')
  final int? paymentAmount;

  /// Provider record creation time, absent before payment begins.
  @Sqlx(rename: 'payment_created_at')
  final String? paymentCreatedAtText;

  /// Public provider identifier, absent before payment begins.
  @Sqlx(rename: 'payment_provider')
  final String? paymentProvider;

  /// Frozen discount in integer minor units.
  @Sqlx(rename: 'discount_total')
  final int orderDiscountTotal;

  /// Frozen delivery amount in integer minor units.
  @Sqlx(rename: 'shipping_total')
  final int orderShippingTotal;

  /// Frozen goods subtotal in integer minor units.
  @Sqlx(rename: 'subtotal')
  final int orderSubtotal;

  /// Frozen tax in integer minor units.
  @Sqlx(rename: 'tax')
  final int orderTax;

  /// Frozen charged amount in integer minor units.
  @Sqlx(rename: 'total')
  final int orderTotal;

  /// Placement timestamp stored as UTC ISO-8601 text.
  @Sqlx(rename: 'placed_at')
  final String placedAtText;

  /// Region country codes in their compact database representation.
  @Sqlx(rename: 'countries')
  final String regionCountries;

  /// Region identifier captured by the order.
  @Sqlx(rename: 'region_id')
  final String regionId;

  /// Region display name.
  @Sqlx(rename: 'region_name')
  final String regionName;

  /// SQLite integer representation of tax inclusion.
  @Sqlx(rename: 'tax_inclusive')
  final int regionTaxInclusive;

  /// Region tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int regionTaxRate;

  /// Shipping address encoded by SQLite's JSON functions.
  @Sqlx(rename: 'shipping_address_json')
  final String shippingAddressJson;

  /// Delivery service name captured at checkout.
  @Sqlx(rename: 'shipping_name')
  final String? shippingName;

  /// Delivery option captured at checkout.
  @Sqlx(rename: 'shipping_option_id')
  final String? shippingOptionId;

  /// Payment lifecycle value stored in SQLite.
  @Sqlx(rename: 'payment_status')
  final String storedPaymentStatus;

  /// Order lifecycle value stored in SQLite.
  @Sqlx(rename: 'status')
  final String storedStatus;

  /// Billing destination decoded from the query aggregate.
  Address get billingAddress => _address(billingAddressJson);

  /// Customer owner, absent for guest checkout.
  String? get customerId => orderCustomerId;

  /// Contact email captured at checkout.
  String get email => orderEmail;

  /// Stable order identifier.
  String get id => orderId;

  /// Explicit frozen line responses.
  List<LineItemResponse> get items => _items(itemsJson);

  /// Current payment lifecycle.
  PaymentStatus get paymentStatus => PaymentStatus.values.firstWhere(
        (status) => status.name == storedPaymentStatus,
        orElse: () => PaymentStatus.awaiting,
      );

  /// Safe payment receipt once provider authorization has started.
  OrderPaymentResponse? get payment {
    final provider = paymentProvider;
    final amount = paymentAmount;
    final createdAt = paymentCreatedAtText;
    if (provider == null || amount == null || createdAt == null) return null;
    return OrderPaymentResponse(
      providerId: provider,
      amount: _money(amount),
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// UTC placement time.
  DateTime get placedAt => DateTime.parse(placedAtText);

  /// Explicit region response captured with the order.
  RegionResponse get region => RegionResponse(
        id: regionId,
        name: regionName,
        currencyCode: currencyCode,
        taxRate: regionTaxRate,
        countries: regionCountries
            .split(',')
            .where((country) => country.isNotEmpty)
            .toList(growable: false),
        taxInclusive: regionTaxInclusive != 0,
      );

  /// Shipping destination decoded from the query aggregate.
  Address get shippingAddress => _address(shippingAddressJson);

  /// Current order lifecycle.
  OrderStatus get status => OrderStatus.values.firstWhere(
        (status) => status.name == storedStatus,
        orElse: () => OrderStatus.pending,
      );

  /// Frozen discount amount.
  Money get discountTotal => _money(orderDiscountTotal);

  /// Explicit frozen shipping method, when selected.
  ShippingMethodResponse? get shippingMethod => shippingOptionId == null
      ? null
      : ShippingMethodResponse(
          optionId: shippingOptionId!,
          name: shippingName ?? 'Delivery',
          amount: shippingTotal,
        );

  /// Frozen delivery amount.
  Money get shippingTotal => _money(orderShippingTotal);

  /// Frozen goods subtotal.
  Money get subtotal => _money(orderSubtotal);

  /// Frozen tax amount.
  Money get tax => _money(orderTax);

  /// Frozen charged amount.
  Money get total => _money(orderTotal);

  Money _money(int amount) => Money(amount: amount, currencyCode: currencyCode);

  /// Returns the response state after successful payment capture.
  OrderResponse captured() => OrderResponse(
        orderId: orderId,
        displayId: displayId,
        orderEmail: orderEmail,
        orderCustomerId: orderCustomerId,
        currencyCode: currencyCode,
        orderSubtotal: orderSubtotal,
        orderShippingTotal: orderShippingTotal,
        orderDiscountTotal: orderDiscountTotal,
        orderTax: orderTax,
        orderTotal: orderTotal,
        storedStatus: OrderStatus.completed.name,
        storedPaymentStatus: PaymentStatus.captured.name,
        placedAtText: placedAtText,
        regionId: regionId,
        regionName: regionName,
        regionTaxRate: regionTaxRate,
        regionTaxInclusive: regionTaxInclusive,
        regionCountries: regionCountries,
        itemsJson: itemsJson,
        shippingAddressJson: shippingAddressJson,
        billingAddressJson: billingAddressJson,
        paymentAmount: paymentAmount,
        paymentCreatedAtText: paymentCreatedAtText,
        paymentProvider: paymentProvider,
        shippingOptionId: shippingOptionId,
        shippingName: shippingName,
      );

  @override
  Map<String, Object?> serialize() => <String, Object?>{
        'id': id,
        'display_id': displayId,
        'email': email,
        'customer_id': customerId,
        'region': region,
        'items': items,
        'subtotal': subtotal,
        'shipping_total': shippingTotal,
        'discount_total': discountTotal,
        'shipping_method': shippingMethod,
        'tax': tax,
        'total': total,
        'shipping_address': shippingAddress,
        'billing_address': billingAddress,
        'placed_at': placedAt,
        'payment': payment,
        'status': status.name,
        'payment_status': paymentStatus.name,
      };

  @override
  Map<String, Object?> toJson() => serialize();

  static Address _address(String source) =>
      Address.fromJson(jsonDecode(source) as Map<String, Object?>);

  static List<LineItemResponse> _items(String source) => [
        for (final value in jsonDecode(source) as List<Object?>)
          LineItemsFromJson.decodeItem(value! as Map<String, Object?>),
      ];
}

/// Explicit order-history envelope.
@Derive([Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class OrderListResponse with _$OrderListResponse {
  /// Builds a counted response from complete orders.
  OrderListResponse.of(this.orders) : count = orders.length;

  /// Number of orders returned.
  final int count;

  /// Explicit order response allowlists, newest first.
  final List<OrderResponse> orders;
}
