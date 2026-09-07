import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/product_type_model.dart';
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
  AND ($2 = '' OR instr(',' || $2 || ',', ',' || product.status || ',') > 0)
  AND ($3 = '' OR EXISTS (
    SELECT 1
    FROM product_tag_products tag_link
    JOIN product_tags tag ON tag.id = tag_link.tag_id
    WHERE tag_link.product_id = product.id AND tag.deleted_at IS NULL
      AND instr(',' || $3 || ',', ',' || tag_link.tag_id || ',') > 0
  ))
  AND ($4 = '' OR instr(',' || $4 || ',', ',' || product.type_id || ',') > 0)
  AND ($5 = '' OR product.created_at > $5)
  AND ($6 = '' OR product.created_at >= $6)
  AND ($7 = '' OR product.created_at < $7)
  AND ($8 = '' OR product.created_at <= $8)
  AND ($9 = '' OR product.updated_at > $9)
  AND ($10 = '' OR product.updated_at >= $10)
  AND ($11 = '' OR product.updated_at < $11)
  AND ($12 = '' OR product.updated_at <= $12)
GROUP BY product.id, product.title, product.thumbnail, collection.title,
         product.status, product.created_at, product.updated_at
ORDER BY
  CASE WHEN $13 = 'title' THEN lower(product.title) END ASC,
  CASE WHEN $13 = '-title' THEN lower(product.title) END DESC,
  CASE WHEN $13 = 'created_at' THEN product.created_at END ASC,
  CASE WHEN $13 = '-created_at' THEN product.created_at END DESC,
  CASE WHEN $13 = 'updated_at' THEN product.updated_at END ASC,
  CASE WHEN $13 = '-updated_at' THEN product.updated_at END DESC,
  product.id ASC
LIMIT $14 OFFSET $15
''')
  Future<Result<List<AdminProductResponse>, SqlxError>> list(
    String query,
    String statuses,
    String tagIds,
    String typeIds,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
    String order,
    int limit,
    int offset,
  );

  /// Counts active products matching the same search and filter set.
  @Query(r'''
SELECT count(*)
FROM products product
WHERE product.deleted_at IS NULL
  AND ($1 = '' OR lower(product.title) LIKE '%' || lower($1) || '%'
       OR lower(product.handle) LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR instr(',' || $2 || ',', ',' || product.status || ',') > 0)
  AND ($3 = '' OR EXISTS (
    SELECT 1
    FROM product_tag_products tag_link
    JOIN product_tags tag ON tag.id = tag_link.tag_id
    WHERE tag_link.product_id = product.id AND tag.deleted_at IS NULL
      AND instr(',' || $3 || ',', ',' || tag_link.tag_id || ',') > 0
  ))
  AND ($4 = '' OR instr(',' || $4 || ',', ',' || product.type_id || ',') > 0)
  AND ($5 = '' OR product.created_at > $5)
  AND ($6 = '' OR product.created_at >= $6)
  AND ($7 = '' OR product.created_at < $7)
  AND ($8 = '' OR product.created_at <= $8)
  AND ($9 = '' OR product.updated_at > $9)
  AND ($10 = '' OR product.updated_at >= $10)
  AND ($11 = '' OR product.updated_at < $11)
  AND ($12 = '' OR product.updated_at <= $12)
''')
  Future<Result<int, SqlxError>> count(
    String query,
    String statuses,
    String tagIds,
    String typeIds,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
  );
}

/// Read-only product-type discovery used by Admin filters.
@SqlxDao()
abstract final class AdminProductTypeRepository {
  /// Binds product-type list queries to [db].
  const factory AdminProductTypeRepository(DatabaseExecutor db) =
      _$AdminProductTypeRepository;

  /// Lists active product types with Medusa's default allowlist.
  @Query(r'''
SELECT id, value, created_at, updated_at
FROM product_types
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(value) LIKE '%' || lower($1) || '%')
ORDER BY lower(value), id
LIMIT $2 OFFSET $3
''')
  Future<Result<List<AdminProductTypeResponse>, SqlxError>> list(
    String query,
    int limit,
    int offset,
  );

  /// Counts the same active product-type search result.
  @Query(r'''
SELECT count(*)
FROM product_types
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(value) LIKE '%' || lower($1) || '%')
''')
  Future<Result<int, SqlxError>> count(String query);
}
