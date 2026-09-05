import 'package:commerce_server/src/features/cart/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The reads that load a cart and its lines.
@SqlxDao()
abstract final class CartReadRepository {
  /// Binds the queries to [db].
  const factory CartReadRepository(DatabaseExecutor db) = _$CartReadRepository;

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
}
