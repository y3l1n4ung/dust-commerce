import 'package:commerce_server/src/features/cart/repository/cart_row.dart';
import 'package:commerce_server/src/features/checkout/repository/order_row.dart';
import 'package:dust_dart/db.dart';

part 'checkout_repository.g.dart';

/// Every query the checkout feature makes.
@SqlxDao()
abstract final class CheckoutRepository {
  /// Binds the queries to [db].
  const factory CheckoutRepository(DatabaseExecutor db) = _$CheckoutRepository;

  /// Writes the order header with its totals already computed.
  @Query(r'''
INSERT INTO orders (id, region_id, customer_id, email, currency_code,
                    subtotal, tax, total, placed_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
''')
  Future<Result<ExecResult, SqlxError>> insertOrder(
    String id,
    String regionId,
    String? customerId,
    String email,
    String currencyCode,
    int subtotal,
    int tax,
    int total,
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

  /// Empties the cart once its lines have been copied onto the order.
  @Query(r'DELETE FROM line_items WHERE cart_id = $1')
  Future<Result<ExecResult, SqlxError>> clearCart(String cartId);

  /// One order with the region it was sold under.
  @Query(r'''
SELECT o.id, o.email, o.customer_id, o.currency_code, o.subtotal, o.tax,
       o.total, o.status, o.payment_status, o.placed_at, o.region_id,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries
FROM orders o
JOIN regions r ON r.id = o.region_id
WHERE o.id = $1
''')
  Future<Result<OrderRow?, SqlxError>> findOrder(String id);

  /// The lines of an order.
  @Query(r'''
SELECT id, variant_id, product_id, title, variant_title,
       unit_amount, currency_code, quantity
FROM order_items
WHERE order_id = $1
ORDER BY rowid
''')
  Future<Result<List<LineItemRow>, SqlxError>> itemsOf(String orderId);

  /// The addresses recorded for an order.
  @Query(r'''
SELECT kind, first_name, last_name, line1, line2, city, province,
       postal_code, country_code, phone
FROM order_addresses
WHERE order_id = $1
''')
  Future<Result<List<OrderAddressRow>, SqlxError>> addressesOf(String orderId);

  /// The orders placed by one email address, newest first.
  ///
  /// Scoped by email in SQL. A history endpoint that filters in Dart is one
  /// forgotten line away from showing somebody else's orders.
  @Query(r'''
SELECT o.id, o.email, o.customer_id, o.currency_code, o.subtotal, o.tax,
       o.total, o.status, o.payment_status, o.placed_at, o.region_id,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries
FROM orders o
JOIN regions r ON r.id = o.region_id
WHERE o.email = $1
ORDER BY o.placed_at DESC, o.id DESC
''')
  Future<Result<List<OrderRow>, SqlxError>> ordersFor(String email);
}
