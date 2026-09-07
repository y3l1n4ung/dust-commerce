import 'package:commerce_server/src/features/admin/model.dart';
import 'package:dust_dart/db.dart';

part 'product.g.dart';

/// Product detail reads live under the read operation without an ORM layer.
@SqlxDao()
abstract final class AdminProductReadRepository {
  /// Binds one-shot product detail reads to [db].
  const factory AdminProductReadRepository(DatabaseExecutor db) =
      _$AdminProductReadRepository;

  /// Reads every currently modeled Medusa detail section in one SQL row.
  @Query(r'''
SELECT product.id, product.title, product.subtitle, product.handle,
       product.description, product.discountable, product.thumbnail,
       product.material, product.origin_country,
       product.product_type, product.weight, product.length, product.width,
       product.height, product.status, collection.title AS collection_title,
       coalesce((
         SELECT json_group_array(json(ordered.image_json))
         FROM (
           SELECT json_object(
             'id', image.id,
             'url', image.url,
             'variant_ids', json(coalesce((
               SELECT json_group_array(link.variant_id)
               FROM product_image_variants link
               WHERE link.image_id = image.id
               ORDER BY link.variant_id
             ), '[]'))
           ) AS image_json
           FROM product_images image
           WHERE image.product_id = product.id AND image.deleted_at IS NULL
           ORDER BY image.rank, image.id
         ) ordered
       ), '[]') AS images,
       coalesce((
         SELECT json_group_array(json(ordered.option_json))
         FROM (
           SELECT json_object(
             'id', option.id, 'title', option.title,
             'values', json(coalesce((
               SELECT json_group_array(value_ordered.value)
               FROM (
                 SELECT value.value FROM product_option_values value
                 WHERE value.option_id = option.id
                   AND value.deleted_at IS NULL
                 ORDER BY value.rank, value.id
               ) value_ordered
             ), '[]'))
           ) AS option_json
           FROM product_options option
           WHERE option.product_id = product.id AND option.deleted_at IS NULL
           ORDER BY option.rank, option.id
         ) ordered
       ), '[]') AS options,
       coalesce((
         SELECT json_group_array(json(ordered.variant_json))
         FROM (
           SELECT json_object(
             'id', variant.id, 'title', variant.title, 'sku', variant.sku,
             'material', variant.material, 'ean', variant.ean,
             'upc', variant.upc,
             'barcode', variant.barcode,
             'weight', variant.weight, 'width', variant.width,
             'length', variant.length, 'height', variant.height,
             'mid_code', variant.mid_code, 'hs_code', variant.hs_code,
             'origin_country', variant.origin_country,
             'inventory_quantity', variant.inventory_quantity,
             'manage_inventory', json(iif(variant.manage_inventory = 1,
                                          'true', 'false')),
             'allow_backorder', json(iif(variant.allow_backorder = 1,
                                         'true', 'false')),
             'option_values', json(coalesce((
               SELECT json_group_object(choice.option_id, value.value)
               FROM variant_option_values choice
               JOIN product_option_values value
                 ON value.id = choice.option_value_id
                AND value.option_id = choice.option_id
               WHERE choice.variant_id = variant.id
                 AND value.deleted_at IS NULL
             ), '{}'))
           ) AS variant_json
           FROM product_variants variant
           WHERE variant.product_id = product.id
             AND variant.deleted_at IS NULL
           ORDER BY variant.id
         ) ordered
       ), '[]') AS variants,
       coalesce((
         SELECT json_group_array(ordered.name)
         FROM (
           SELECT category.name
           FROM product_category_products link
           JOIN product_categories category ON category.id = link.category_id
           WHERE link.product_id = product.id
             AND category.deleted_at IS NULL
           ORDER BY link.rank, category.name
         ) ordered
       ), '[]') AS categories,
       coalesce((
         SELECT json_group_array(ordered.value)
         FROM (
           SELECT tag.value
           FROM product_tag_products link
           JOIN product_tags tag ON tag.id = link.tag_id
           WHERE link.product_id = product.id AND tag.deleted_at IS NULL
           ORDER BY tag.value
         ) ordered
       ), '[]') AS tags
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.id = $1 AND product.deleted_at IS NULL
''')
  Future<Result<AdminProductDetailResponse?, SqlxError>> findById(String id);
}
