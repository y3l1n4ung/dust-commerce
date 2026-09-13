import 'package:commerce_server/src/features/admin/product_export_model.dart';
import 'package:dust_dart/db.dart';

part 'export.g.dart';

/// Direct product graph reads for merchant CSV export.
@SqlxDao()
abstract final class AdminProductExportRepository {
  /// Binds product export reads to [db].
  const factory AdminProductExportRepository(DatabaseExecutor db) =
      _$AdminProductExportRepository;

  /// Reads every matching product once; Dart expands its ordered child graphs.
  @Query(r'''
SELECT product.id AS product_id, product.handle, product.title,
       product.subtitle, product.description, product.status,
       product.thumbnail, product.weight, product.length, product.width,
       product.height, product.origin_country, product.material,
       product.collection_id, product.type_id, product.discountable,
       coalesce((
         SELECT json_group_array(json(ordered.option_json)) FROM (
           SELECT json_object('id', option.id, 'title', option.title) option_json
           FROM product_product_options link
           JOIN product_options option ON option.id = link.product_option_id
           WHERE link.product_id = product.id AND link.deleted_at IS NULL
             AND option.deleted_at IS NULL ORDER BY link.rowid
         ) ordered
       ), '[]') AS options_json,
       coalesce((
         SELECT json_group_array(json(ordered.variant_json)) FROM (
           SELECT json_object(
             'id', variant.id, 'title', variant.title, 'sku', variant.sku,
             'barcode', variant.barcode, 'weight', variant.weight,
             'length', variant.length, 'width', variant.width,
             'height', variant.height, 'hs_code', variant.hs_code,
             'origin_country', variant.origin_country,
             'mid_code', variant.mid_code, 'material', variant.material,
             'allow_backorder', json(iif(variant.allow_backorder=1,'true','false')),
             'manage_inventory', json(iif(variant.manage_inventory=1,'true','false')),
             'prices', json(coalesce((
               SELECT json_group_array(json(prices.price_json)) FROM (
                 SELECT json_object('currency_code', price.currency_code,
                   'amount', price.amount) price_json FROM variant_prices price
                 WHERE price.variant_id = variant.id ORDER BY price.currency_code
               ) prices
             ), '[]')),
             'option_values', json(coalesce((
               SELECT json_group_object(choice.option_id, value.value)
               FROM variant_option_values choice
               JOIN product_option_values value ON value.id=choice.option_value_id
                 AND value.option_id=choice.option_id
               WHERE choice.variant_id=variant.id AND value.deleted_at IS NULL
             ), '{}'))
           ) variant_json FROM product_variants variant
           WHERE variant.product_id=product.id AND variant.deleted_at IS NULL
           ORDER BY variant.rowid
         ) ordered
       ), '[]') AS variants_json,
       coalesce((SELECT json_group_array(ordered.url) FROM (
         SELECT image.url FROM product_images image
         WHERE image.product_id=product.id AND image.deleted_at IS NULL
         ORDER BY image.rank, image.id) ordered), '[]') AS images_json,
       coalesce((SELECT json_group_array(ordered.value) FROM (
         SELECT tag.value FROM product_tag_products link
         JOIN product_tags tag ON tag.id=link.tag_id
         WHERE link.product_id=product.id AND tag.deleted_at IS NULL
         ORDER BY tag.value) ordered), '[]') AS tags_json
FROM products product
WHERE product.deleted_at IS NULL
  AND ($1='' OR lower(product.title) LIKE '%'||lower($1)||'%'
       OR lower(product.handle) LIKE '%'||lower($1)||'%')
  AND ($2='' OR instr(','||$2||',', ','||product.status||',')>0)
  AND ($3='' OR EXISTS (SELECT 1 FROM product_tag_products tag_link
    JOIN product_tags tag ON tag.id=tag_link.tag_id
    WHERE tag_link.product_id=product.id AND tag.deleted_at IS NULL
      AND instr(','||$3||',', ','||tag_link.tag_id||',')>0))
  AND ($4='' OR instr(','||$4||',', ','||product.type_id||',')>0)
  AND ($5='' OR product.created_at>$5)
  AND ($6='' OR product.created_at>=$6)
  AND ($7='' OR product.created_at<$7)
  AND ($8='' OR product.created_at<=$8)
  AND ($9='' OR product.updated_at>$9)
  AND ($10='' OR product.updated_at>=$10)
  AND ($11='' OR product.updated_at<$11)
  AND ($12='' OR product.updated_at<=$12)
ORDER BY CASE WHEN $13='title' THEN lower(product.title) END ASC,
  CASE WHEN $13='-title' THEN lower(product.title) END DESC,
  CASE WHEN $13='created_at' THEN product.created_at END ASC,
  CASE WHEN $13='-created_at' THEN product.created_at END DESC,
  CASE WHEN $13='updated_at' THEN product.updated_at END ASC,
  CASE WHEN $13='-updated_at' THEN product.updated_at END DESC, product.id ASC
''')
  Future<Result<List<AdminProductExportRow>, SqlxError>> list(
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
  );
}
