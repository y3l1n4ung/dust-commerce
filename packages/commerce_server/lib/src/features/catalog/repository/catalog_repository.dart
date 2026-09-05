import 'package:commerce_server/src/features/catalog/repository/product_row.dart';
import 'package:dust_dart/db.dart';

part 'catalog_repository.g.dart';

/// Every query the catalogue feature makes.
///
/// One DAO per feature, bound to a [DatabaseExecutor] so the same queries run
/// on the connection or inside a transaction. A feature owning its own
/// queries is what keeps a schema change to one directory.
///
/// The SQL here is checked against the schema when `dust db build` runs, so a
/// column that does not exist is a build error rather than a 500 in
/// production.
@SqlxDao()
abstract final class CatalogRepository {
  /// Binds the queries to [db].
  const factory CatalogRepository(DatabaseExecutor db) = _$CatalogRepository;

  /// Published products, newest handles last, for a storefront listing.
  ///
  /// Draft and rejected products are excluded in SQL rather than in Dart. A
  /// filter that lives in the query cannot be forgotten by a caller.
  @Query(r'''
SELECT id, title, handle, description, thumbnail, status
FROM products
WHERE status = 'published'
ORDER BY handle
LIMIT $1 OFFSET $2
''')
  Future<Result<List<ProductRow>, SqlxError>> listPublished(
    int limit,
    int offset,
  );

  /// One published product by the handle the storefront routed on.
  @Query(r'''
SELECT id, title, handle, description, thumbnail, status
FROM products
WHERE handle = $1 AND status = 'published'
''')
  Future<Result<ProductRow?, SqlxError>> findByHandle(String handle);

  /// The variants of [productId], each with its price in [currencyCode].
  ///
  /// Joined rather than fetched separately: a variant with no price in the
  /// requested currency is not sellable there, and the join drops it without
  /// Dart having to decide.
  @Query(r'''
SELECT v.id, v.product_id, v.title, v.sku, v.inventory_quantity,
       v.manage_inventory, v.allow_backorder,
       p.currency_code, p.amount
FROM product_variants v
JOIN variant_prices p ON p.variant_id = v.id
WHERE v.product_id = $1 AND p.currency_code = $2
ORDER BY v.id
''')
  Future<Result<List<VariantRow>, SqlxError>> variantsOf(
    String productId,
    String currencyCode,
  );

  /// One variant with its price, for adding a line to a cart.
  @Query(r'''
SELECT v.id, v.product_id, v.title, v.sku, v.inventory_quantity,
       v.manage_inventory, v.allow_backorder,
       p.currency_code, p.amount
FROM product_variants v
JOIN variant_prices p ON p.variant_id = v.id
WHERE v.id = $1 AND p.currency_code = $2
''')
  Future<Result<VariantRow?, SqlxError>> findVariant(
    String variantId,
    String currencyCode,
  );

  /// How many published products there are, for a paged listing.
  @Query(r'''
SELECT COUNT(*) AS total
FROM products
WHERE status = 'published'
''')
  Future<Result<int, SqlxError>> countPublished();
}
