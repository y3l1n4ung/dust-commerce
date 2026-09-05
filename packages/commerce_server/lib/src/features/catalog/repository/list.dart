import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// The catalogue's complete-response list queries.
@SqlxDao()
abstract final class CatalogListRepository {
  /// Binds the queries to [db].
  const factory CatalogListRepository(DatabaseExecutor db) =
      _$CatalogListRepository;

  /// Published products with complete currency-scoped storefront data.
  @Query(r'''
SELECT product.id, product.title, product.handle, product.description,
       product.thumbnail, product.status,
       CASE WHEN collection.id IS NULL THEN 'null' ELSE json_object(
         'id', collection.id,
         'title', collection.title,
         'handle', collection.handle
       ) END AS collection,
       json_object(
         'material', product.material,
         'origin_country', product.origin_country,
         'product_type', product.product_type,
         'weight', product.weight,
         'length', product.length,
         'width', product.width,
         'height', product.height
       ) AS details,
       coalesce((
         SELECT json_group_array(ordered.url)
         FROM (
           SELECT image.url
           FROM product_images image
           WHERE image.product_id = product.id AND image.deleted_at IS NULL
           ORDER BY image.rank
         ) ordered
       ), '[]') AS images,
       coalesce((
         SELECT json_group_array(json(ordered.category_json))
         FROM (
           SELECT json_object(
             'id', category.id,
             'name', category.name,
             'description', category.description,
             'handle', category.handle,
             'parent_id', category.parent_category_id
           ) AS category_json
           FROM product_category_products link
           JOIN product_categories category ON category.id = link.category_id
           WHERE link.product_id = product.id
             AND category.is_active = 1
             AND category.deleted_at IS NULL
           ORDER BY link.rank, category.handle
         ) ordered
       ), '[]') AS categories,
       coalesce((
         SELECT json_group_array(json(ordered.tag_json))
         FROM (
           SELECT json_object('id', tag.id, 'value', tag.value) AS tag_json
           FROM product_tag_products link
           JOIN product_tags tag ON tag.id = link.tag_id
           WHERE link.product_id = product.id AND tag.deleted_at IS NULL
           ORDER BY tag.value
         ) ordered
       ), '[]') AS tags,
       coalesce((
         SELECT json_group_array(json(ordered.option_json))
         FROM (
           SELECT json_object(
             'id', option.id,
             'title', option.title,
             'values_csv', option.values_csv
           ) AS option_json
           FROM product_options option
           WHERE option.product_id = product.id AND option.deleted_at IS NULL
           ORDER BY option.id
         ) ordered
       ), '[]') AS options,
       coalesce((
         SELECT json_group_array(json(ordered.variant_json))
         FROM (
           SELECT json_object(
             'id', variant.id,
             'title', variant.title,
             'sku', variant.sku,
             'inventory_quantity', variant.inventory_quantity,
             'manage_inventory', variant.manage_inventory,
             'allow_backorder', variant.allow_backorder,
             'amount', price.amount,
             'currency_code', price.currency_code,
             'option_values', json(coalesce((
               SELECT json_group_object(choice.option_id, choice.value)
               FROM variant_option_values choice
               WHERE choice.variant_id = variant.id
             ), '{}'))
           ) AS variant_json
           FROM product_variants variant
           JOIN variant_prices price ON price.variant_id = variant.id
           WHERE variant.product_id = product.id
             AND variant.deleted_at IS NULL
             AND price.currency_code = $1
           ORDER BY variant.id
         ) ordered
       ), '[]') AS variants
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.status = 'published' AND product.deleted_at IS NULL
  AND ($4 IS NULL OR collection.handle = $4)
  AND ($5 IS NULL OR EXISTS (
    SELECT 1
    FROM product_category_products filter_link
    JOIN product_categories filter_category
      ON filter_category.id = filter_link.category_id
    WHERE filter_link.product_id = product.id
      AND filter_category.handle = $5
      AND filter_category.is_active = 1
      AND filter_category.deleted_at IS NULL
  ))
  AND ($6 IS NULL OR EXISTS (
    SELECT 1
    FROM product_tag_products filter_link
    JOIN product_tags filter_tag ON filter_tag.id = filter_link.tag_id
    WHERE filter_link.product_id = product.id
      AND lower(filter_tag.value) = lower($6)
      AND filter_tag.deleted_at IS NULL
  ))
-- Latest arrivals are the source storefront default; handle is deterministic
-- when a bulk insert gives multiple products the same generated timestamp.
ORDER BY product.created_at DESC, product.handle
LIMIT $2 OFFSET $3
''')
  Future<Result<List<ProductResponse>, SqlxError>> listPublished(
    String currencyCode,
    int limit,
    int offset,
    String? collectionHandle,
    String? categoryHandle,
    String? tag,
  );

  /// How many published products there are, for a paged listing.
  @Query(r'''
SELECT COUNT(*) AS total
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.status = 'published' AND product.deleted_at IS NULL
  AND ($1 IS NULL OR collection.handle = $1)
  AND ($2 IS NULL OR EXISTS (
    SELECT 1
    FROM product_category_products filter_link
    JOIN product_categories filter_category
      ON filter_category.id = filter_link.category_id
    WHERE filter_link.product_id = product.id
      AND filter_category.handle = $2
      AND filter_category.is_active = 1
      AND filter_category.deleted_at IS NULL
  ))
  AND ($3 IS NULL OR EXISTS (
    SELECT 1
    FROM product_tag_products filter_link
    JOIN product_tags filter_tag ON filter_tag.id = filter_link.tag_id
    WHERE filter_link.product_id = product.id
      AND lower(filter_tag.value) = lower($3)
      AND filter_tag.deleted_at IS NULL
  ))
''')
  Future<Result<int, SqlxError>> countPublished(
    String? collectionHandle,
    String? categoryHandle,
    String? tag,
  );
}
