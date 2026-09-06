import 'package:commerce_server/src/features/admin/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// Merchant catalogue reads kept separate from authentication persistence.
@SqlxDao()
abstract final class AdminProductRepository {
  /// Binds product queries to [db].
  const factory AdminProductRepository(DatabaseExecutor db) =
      _$AdminProductRepository;

  /// Lists active products with the exact columns used by Medusa's table.
  @Query(r'''
SELECT product.id,
       product.title,
       coalesce(product.thumbnail, '') AS thumbnail,
       coalesce(collection.title, '') AS collection_title,
       '' AS sales_channels,
       count(variant.id) AS variant_count,
       product.status
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
LEFT JOIN product_variants variant
  ON variant.product_id = product.id AND variant.deleted_at IS NULL
WHERE product.deleted_at IS NULL
  AND ($1 = '' OR lower(product.title) LIKE '%' || lower($1) || '%'
       OR lower(product.handle) LIKE '%' || lower($1) || '%')
GROUP BY product.id, product.title, product.thumbnail, collection.title,
         product.status, product.created_at
ORDER BY product.created_at DESC, product.id
LIMIT $2 OFFSET $3
''')
  Future<Result<List<AdminProductResponse>, SqlxError>> list(
    String query,
    int limit,
    int offset,
  );

  /// Counts active products matching the same title-or-handle query.
  @Query(r'''
SELECT count(*)
FROM products product
WHERE product.deleted_at IS NULL
  AND ($1 = '' OR lower(product.title) LIKE '%' || lower($1) || '%'
       OR lower(product.handle) LIKE '%' || lower($1) || '%')
''')
  Future<Result<int, SqlxError>> count(String query);
}
