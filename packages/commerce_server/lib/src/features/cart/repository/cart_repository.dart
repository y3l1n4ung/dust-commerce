import 'package:commerce_server/src/features/cart/repository/cart_row.dart';
import 'package:dust_dart/db.dart';

part 'cart_repository.g.dart';

/// Every query the cart feature makes.
@SqlxDao()
abstract final class CartRepository {
  /// Binds the queries to [db].
  const factory CartRepository(DatabaseExecutor db) = _$CartRepository;

  /// Starts a cart in [regionId].
  @Query(r'''
INSERT INTO carts (id, region_id, customer_id, email, created_at)
VALUES ($1, $2, $3, $4, $5)
''')
  Future<Result<ExecResult, SqlxError>> createCart(
    String id,
    String regionId,
    String? customerId,
    String? email,
    String createdAt,
  );

  /// One cart with the region that fixes its currency and tax.
  ///
  /// Joined rather than fetched in two calls: a cart without its region cannot
  /// total anything, so there is no useful state in which one is loaded
  /// without the other.
  @Query(r'''
SELECT c.id, c.region_id, c.customer_id, c.email,
       r.name AS region_name, r.currency_code, r.tax_rate,
       r.tax_inclusive, r.countries
FROM carts c
JOIN regions r ON r.id = c.region_id
WHERE c.id = $1
''')
  Future<Result<CartRow?, SqlxError>> findCart(String id);

  /// The lines of [cartId], in insertion order.
  @Query(r'''
SELECT id, variant_id, product_id, title, variant_title,
       unit_amount, currency_code, quantity
FROM line_items
WHERE cart_id = $1
ORDER BY rowid
''')
  Future<Result<List<LineItemRow>, SqlxError>> linesOf(String cartId);

  /// The line for [variantId] in [cartId], if the cart already holds one.
  @Query(r'''
SELECT id, variant_id, product_id, title, variant_title,
       unit_amount, currency_code, quantity
FROM line_items
WHERE cart_id = $1 AND variant_id = $2
''')
  Future<Result<LineItemRow?, SqlxError>> findLine(
    String cartId,
    String variantId,
  );

  /// Adds a line, with the price snapshot taken by the caller.
  @Query(r'''
INSERT INTO line_items (id, cart_id, variant_id, product_id, title,
                        variant_title, unit_amount, currency_code, quantity)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
''')
  Future<Result<ExecResult, SqlxError>> insertLine(
    String id,
    String cartId,
    String variantId,
    String productId,
    String title,
    String? variantTitle,
    int unitAmount,
    String currencyCode,
    int quantity,
  );

  /// Sets the quantity of an existing line, keeping its price snapshot.
  @Query(r'UPDATE line_items SET quantity = $2 WHERE id = $1')
  Future<Result<ExecResult, SqlxError>> setLineQuantity(
    String lineId,
    int quantity,
  );

  /// Removes a line.
  @Query(r'DELETE FROM line_items WHERE id = $1 AND cart_id = $2')
  Future<Result<ExecResult, SqlxError>> deleteLine(
    String lineId,
    String cartId,
  );

  /// Records the email a guest checkout collected.
  @Query(r'UPDATE carts SET email = $2 WHERE id = $1')
  Future<Result<ExecResult, SqlxError>> setCartEmail(
    String cartId,
    String email,
  );

  /// The default region, for a storefront that has not chosen one.
  @Query(r'''
SELECT id, name, currency_code, tax_rate, tax_inclusive, countries
FROM regions
ORDER BY id
LIMIT 1
''')
  Future<Result<RegionRow?, SqlxError>> firstRegion();
}
