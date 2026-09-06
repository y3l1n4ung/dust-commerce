import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:dust_dart/db.dart';

part 'products.g.dart';

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
         'id', collection.id, 'title', collection.title, 'handle', collection.handle
       ) END AS collection,
       json_object(
         'material', product.material, 'origin_country', product.origin_country,
         'product_type', product.product_type, 'weight', product.weight,
         'length', product.length, 'width', product.width,
         'height', product.height
       ) AS details,
       coalesce((
         SELECT json_group_array(json(ordered.image_json))
         FROM (
           SELECT json_object('id', image.id, 'url', image.url, 'rank', image.rank) AS image_json
           FROM product_images image
           WHERE image.product_id = product.id AND image.deleted_at IS NULL
           ORDER BY image.rank, image.id
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
             'id', option.id, 'title', option.title,
             'values', json(coalesce((
               SELECT json_group_array(ordered_value.value)
               FROM (
                 SELECT option_value.value
                 FROM product_option_values option_value
                 WHERE option_value.option_id = option.id
                   AND option_value.deleted_at IS NULL
                 ORDER BY option_value.rank, option_value.id
               ) ordered_value
             ), '[]'))
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
             'id', variant.id, 'title', variant.title, 'sku', variant.sku,
             'inventory_quantity', variant.inventory_quantity, 'manage_inventory', variant.manage_inventory,
             'allow_backorder', variant.allow_backorder, 'amount', price.amount,
             'currency_code', price.currency_code,
             'option_values', json(coalesce((
               SELECT json_group_object(choice.option_id, option_value.value)
               FROM variant_option_values choice
               JOIN product_option_values option_value
                 ON option_value.id = choice.option_value_id
                AND option_value.option_id = choice.option_id
               WHERE choice.variant_id = variant.id
                 AND option_value.deleted_at IS NULL
             ), '{}')),
             'images', json(coalesce((
               SELECT json_group_array(json(ordered_image.image_json))
               FROM (
                 SELECT json_object('id', image.id, 'url', image.url, 'rank', image.rank) AS image_json
                 FROM product_image_variants image_variant
                 JOIN product_images image ON image.id = image_variant.image_id
                 WHERE image_variant.variant_id = variant.id
                   AND image.deleted_at IS NULL
                 ORDER BY image.rank, image.id
               ) ordered_image
             ), '[]'))
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
LEFT JOIN product_collections collection ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.status = 'published' AND product.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM product_variants sellable_variant
    JOIN variant_prices sellable_price ON sellable_price.variant_id = sellable_variant.id
    WHERE sellable_variant.product_id = product.id
      AND sellable_variant.deleted_at IS NULL
      AND sellable_price.currency_code = $1
  )
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
  AND (json_array_length($7) = 0 OR EXISTS (
    SELECT 1
    FROM product_variants filter_variant
    JOIN variant_prices filter_price ON filter_price.variant_id = filter_variant.id
    JOIN variant_option_values filter_choice
      ON filter_choice.variant_id = filter_variant.id
    JOIN product_options filter_option
      ON filter_option.id = filter_choice.option_id
     AND filter_option.product_id = product.id
    JOIN product_option_values filter_value
      ON filter_value.id = filter_choice.option_value_id
     AND filter_value.option_id = filter_choice.option_id
    WHERE filter_variant.product_id = product.id
      AND filter_variant.deleted_at IS NULL
      AND filter_price.currency_code = $1
      AND filter_option.deleted_at IS NULL
      AND filter_value.deleted_at IS NULL
      AND filter_choice.option_value_id IN (
        SELECT value FROM json_each($7)
      )
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
    String optionValueIdsJson,
  );
}
