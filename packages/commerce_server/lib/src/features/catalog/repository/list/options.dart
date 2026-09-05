import 'package:commerce_server/src/features/catalog/option_filter_response.dart';
import 'package:dust_dart/db.dart';

part 'options.g.dart';

/// Store-wide product-option refinement queries.
@SqlxDao()
abstract final class CatalogOptionRepository {
  /// Binds the query to [db].
  const factory CatalogOptionRepository(DatabaseExecutor db) =
      _$CatalogOptionRepository;

  /// Active options and values belonging to published products.
  @Query(r'''
SELECT option.id, option.title,
       coalesce((
         SELECT json_group_array(json(ordered.value_json))
         FROM (
           SELECT json_object('id', option_value.id,
                              'value', option_value.value) AS value_json
           FROM product_option_values option_value
           WHERE option_value.option_id = option.id
             AND option_value.deleted_at IS NULL
           ORDER BY option_value.rank, option_value.id
         ) ordered
       ), '[]') AS "values"
FROM product_options option
JOIN products product ON product.id = option.product_id
WHERE option.deleted_at IS NULL
  AND product.status = 'published'
  AND product.deleted_at IS NULL
  AND EXISTS (
    SELECT 1 FROM product_option_values option_value
    WHERE option_value.option_id = option.id
      AND option_value.deleted_at IS NULL
  )
ORDER BY option.title, option.id
LIMIT $1 OFFSET $2
''')
  Future<Result<List<ProductOptionFilterResponse>, SqlxError>> list(
    int limit,
    int offset,
  );
}
