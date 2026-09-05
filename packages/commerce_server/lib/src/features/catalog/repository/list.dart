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
WHERE product.status = 'published' AND product.deleted_at IS NULL
ORDER BY product.handle
LIMIT $2 OFFSET $3
''')
  Future<Result<List<ProductResponse>, SqlxError>> listPublished(
    String currencyCode,
    int limit,
    int offset,
  );

  /// How many published products there are, for a paged listing.
  @Query(r'''
SELECT COUNT(*) AS total
FROM products
WHERE status = 'published' AND deleted_at IS NULL
''')
  Future<Result<int, SqlxError>> countPublished();
}
