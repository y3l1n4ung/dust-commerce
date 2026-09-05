import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:commerce_server/src/features/catalog/sellable_variant.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The catalogue's complete-response single-row reads.
@SqlxDao()
abstract final class CatalogReadRepository {
  /// Binds the queries to [db].
  const factory CatalogReadRepository(DatabaseExecutor db) =
      _$CatalogReadRepository;

  /// One published product with complete currency-scoped storefront data.
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
             AND price.currency_code = $2
           ORDER BY variant.id
         ) ordered
       ), '[]') AS variants
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.handle = $1
  AND product.status = 'published'
  AND product.deleted_at IS NULL
''')
  Future<Result<ProductResponse?, SqlxError>> findByHandle(
    String handle,
    String currencyCode,
  );

  /// One variant with its price, for adding a line to a cart.
  @Query(r'''
SELECT v.id, v.product_id, v.title, v.sku, v.inventory_quantity,
       v.manage_inventory, v.allow_backorder,
       p.currency_code, p.amount, product.title AS product_title,
       product.handle AS product_handle, product.thumbnail
FROM product_variants v
JOIN variant_prices p ON p.variant_id = v.id
JOIN products product ON product.id = v.product_id
WHERE v.id = $1 AND p.currency_code = $2
  AND v.deleted_at IS NULL
  AND product.deleted_at IS NULL
  AND product.status = 'published'
''')
  Future<Result<SellableVariant?, SqlxError>> findVariant(
    String variantId,
    String currencyCode,
  );
}
