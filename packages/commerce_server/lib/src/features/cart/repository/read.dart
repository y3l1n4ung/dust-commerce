// Row types are imported from the library that declares them rather than
// through model/model.dart. Dust resolves a DAO's row type by looking in
// the libraries a file imports and does not follow an export barrel, so a
// barrel import fails the build with 'unsupported DAO result type'.
import 'package:commerce_server/src/features/cart/model/cart.dart';
import 'package:commerce_server/src/features/cart/model/promotion.dart';
import 'package:commerce_server/src/features/cart/model/shipping.dart';
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

  /// The method [cartId] chose, if it has chosen one.
  @Query(r'''
SELECT option_id, name, amount
FROM cart_shipping_methods
WHERE cart_id = $1
''')
  Future<Result<ShippingMethodRow?, SqlxError>> shippingMethodOf(String cartId);

  /// The promotion [cartId] has applied, if it has one.
  @Query(r'''
SELECT promotion_id, code, amount
FROM cart_promotions
WHERE cart_id = $1
''')
  Future<Result<CartPromotionRow?, SqlxError>> promotionOn(String cartId);

  /// One promotion by the code a customer typed.
  ///
  /// Matched upper case in SQL so entry is not case sensitive, which is a
  /// property of the lookup rather than something every caller remembers.
  @Query(r'''
SELECT id, code, type, value, currency_code, starts_at, ends_at,
       usage_limit, usage_count
FROM promotions
WHERE code = UPPER($1)
''')
  Future<Result<PromotionRow?, SqlxError>> promotionByCode(String code);

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
