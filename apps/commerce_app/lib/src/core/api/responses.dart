import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'responses.g.dart';

/// One page of the catalogue, as `GET /store/products` answers it.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class ProductPageResponse with _$ProductPageResponse {
  /// Creates a [ProductPageResponse].
  const ProductPageResponse({
    required this.products,
    required this.count,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Creates a [ProductPageResponse] from JSON.
  factory ProductPageResponse.fromJson(Map<String, Object?> json) =>
      _$ProductPageResponseFromJson(json);

  /// How many are on this page.
  final int count;

  /// How many were asked for.
  final int limit;

  /// How many were skipped.
  final int offset;

  /// The products on this page.
  final List<Product> products;

  /// How many published products exist.
  final int total;
}

/// A cart with the totals the server computed, as the cart endpoints answer.
///
/// The totals travel rather than being recomputed on the client. A storefront
/// that adds up its own lines will one day disagree with the receipt, and the
/// server's answer is the one the customer is charged.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class CartResponse with _$CartResponse {
  /// Creates a [CartResponse].
  const CartResponse({
    required this.id,
    required this.region,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.itemCount,
    this.email,
    this.customerId,
  });

  /// Creates a [CartResponse] from JSON.
  factory CartResponse.fromJson(Map<String, Object?> json) =>
      _$CartResponseFromJson(json);

  /// The account this belongs to, when there is one.
  final String? customerId;

  /// Contact address for a guest checkout.
  final String? email;

  /// Unique identifier.
  final String id;

  /// How many units are in the cart.
  final int itemCount;

  /// The chosen lines.
  final List<LineItem> items;

  /// The selling territory.
  final Region region;

  /// The sum of the lines, before tax.
  final Money subtotal;

  /// The tax the region charges.
  final Money tax;

  /// What the customer pays.
  final Money total;
}

/// The orders one email address has placed.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class OrderListResponse with _$OrderListResponse {
  /// Creates an [OrderListResponse].
  const OrderListResponse({required this.orders, required this.count});

  /// Creates an [OrderListResponse] from JSON.
  factory OrderListResponse.fromJson(Map<String, Object?> json) =>
      _$OrderListResponseFromJson(json);

  /// How many there are.
  final int count;

  /// The orders, newest first.
  final List<Order> orders;
}

/// The body of `POST /store/carts/{id}/line-items`.
@Derive([ToString(), Eq(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class AddLineRequest with _$AddLineRequest {
  /// Creates an [AddLineRequest].
  const AddLineRequest({required this.variantId, this.quantity = 1});

  /// Creates an [AddLineRequest] from JSON.
  factory AddLineRequest.fromJson(Map<String, Object?> json) =>
      _$AddLineRequestFromJson(json);

  /// How many to add.
  final int quantity;

  /// The variant being added.
  final String variantId;
}
