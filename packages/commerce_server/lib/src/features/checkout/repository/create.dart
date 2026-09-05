import 'package:dust_dart/db.dart';

part 'create.g.dart';

/// The writes that turn a cart into an order.
@SqlxDao()
abstract final class CheckoutCreateRepository {
  /// Binds the queries to [db].
  const factory CheckoutCreateRepository(DatabaseExecutor db) =
      _$CheckoutCreateRepository;

  /// Writes the order header with its totals already computed.
  @Query(r'''
INSERT INTO orders (id, region_id, customer_id, email, currency_code,
                    subtotal, shipping_total, discount_total, tax, total,
                    shipping_option_id, shipping_name, placed_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
''')
  Future<Result<ExecResult, SqlxError>> insertOrder(
    String id,
    String regionId,
    String? customerId,
    String email,
    String currencyCode,
    int subtotal,
    int shippingTotal,
    int discountTotal,
    int tax,
    int total,
    String? shippingOptionId,
    String? shippingName,
    String placedAt,
  );

  /// Copies one cart line onto the order.
  @Query(r'''
INSERT INTO order_items (id, order_id, variant_id, product_id, title,
                         variant_title, unit_amount, currency_code, quantity)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
''')
  Future<Result<ExecResult, SqlxError>> insertOrderItem(
    String id,
    String orderId,
    String variantId,
    String productId,
    String title,
    String? variantTitle,
    int unitAmount,
    String currencyCode,
    int quantity,
  );

  /// Records the shipping or billing address used for an order.
  @Query(r'''
INSERT INTO order_addresses (order_id, kind, first_name, last_name, line1,
                             line2, city, province, postal_code, country_code,
                             phone)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
''')
  Future<Result<ExecResult, SqlxError>> insertOrderAddress(
    String orderId,
    String kind,
    String firstName,
    String lastName,
    String line1,
    String? line2,
    String city,
    String? province,
    String postalCode,
    String countryCode,
    String? phone,
  );

  /// Takes stock for a variant, but only if there is enough.
  ///
  /// The check is in the WHERE clause rather than in Dart: two checkouts
  /// racing for the last unit both read "one left", and only the write can
  /// decide which of them gets it. A zero row count is how the loser finds out.
  @Query(r'''
UPDATE product_variants
SET inventory_quantity = inventory_quantity - $2
WHERE id = $1
  AND (manage_inventory = 0 OR allow_backorder = 1
       OR inventory_quantity >= $2)
''')
  Future<Result<ExecResult, SqlxError>> reserveStock(
    String variantId,
    int quantity,
  );

  /// Counts a redemption, so a limited promotion runs out.
  ///
  /// Incremented in SQL rather than read-then-written: two checkouts redeeming
  /// the last use of a code would otherwise both read the same count.
  @Query(r'''
UPDATE promotions SET usage_count = usage_count + 1 WHERE code = $1
''')
  Future<Result<ExecResult, SqlxError>> countRedemption(String code);

  /// Empties the cart once its lines have been copied onto the order.
  @Query(r'DELETE FROM line_items WHERE cart_id = $1')
  Future<Result<ExecResult, SqlxError>> clearCart(String cartId);
}
