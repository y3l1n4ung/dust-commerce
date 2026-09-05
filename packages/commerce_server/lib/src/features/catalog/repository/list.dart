import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// The catalogue's list queries.
///
/// Split from the single-row reads because each operation gets its own file.
/// Dust generates one DAO per annotated class, so an operation-shaped file is
/// an operation-shaped DAO — which is also the smallest thing a caller has to
/// depend on.
@SqlxDao()
abstract final class CatalogListRepository {
  /// Binds the queries to [db].
  const factory CatalogListRepository(DatabaseExecutor db) =
      _$CatalogListRepository;

  /// Published products, ordered by handle, for a storefront listing.
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

  /// The axes [productId] varies along.
  @Query(r'''
SELECT id, product_id, title, values_csv
FROM product_options
WHERE product_id = $1
ORDER BY id
''')
  Future<Result<List<ProductOptionRow>, SqlxError>> optionsOf(String productId);

  /// The option values every variant of [productId] was built from.
  ///
  /// One query for the whole product rather than one per variant. A size
  /// selector needs all of them to render, so fetching them per variant would
  /// be N+1 for data that is always wanted together.
  @Query(r'''
SELECT v.id AS variant_id, o.option_id, o.value
FROM variant_option_values o
JOIN product_variants v ON v.id = o.variant_id
WHERE v.product_id = $1
ORDER BY v.id, o.option_id
''')
  Future<Result<List<VariantOptionValueRow>, SqlxError>> optionValuesOf(
    String productId,
  );

  /// How many published products there are, for a paged listing.
  @Query(r'''
SELECT COUNT(*) AS total
FROM products
WHERE status = 'published'
''')
  Future<Result<int, SqlxError>> countPublished();
}
