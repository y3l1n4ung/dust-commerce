import 'package:dust_dart/db.dart';

part 'count.g.dart';

/// Count query paired with the paged catalogue response.
@SqlxDao()
abstract final class CatalogCountRepository {
  /// Binds the query to [db].
  const factory CatalogCountRepository(DatabaseExecutor db) =
      _$CatalogCountRepository;

  /// How many published products match the active refinements.
  @Query(r'''
SELECT COUNT(*) AS total
FROM products product
LEFT JOIN product_collections collection
  ON collection.id = product.collection_id AND collection.deleted_at IS NULL
WHERE product.status = 'published' AND product.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM product_variants sellable_variant
    JOIN variant_prices sellable_price
      ON sellable_price.variant_id = sellable_variant.id
    WHERE sellable_variant.product_id = product.id
      AND sellable_variant.deleted_at IS NULL
      AND sellable_price.currency_code = $1
  )
  AND ($2 IS NULL OR collection.handle = $2)
  AND ($3 IS NULL OR EXISTS (
    SELECT 1
    FROM product_category_products filter_link
    JOIN product_categories filter_category
      ON filter_category.id = filter_link.category_id
    WHERE filter_link.product_id = product.id
      AND filter_category.handle = $3
      AND filter_category.is_active = 1
      AND filter_category.deleted_at IS NULL
  ))
  AND ($4 IS NULL OR EXISTS (
    SELECT 1
    FROM product_tag_products filter_link
    JOIN product_tags filter_tag ON filter_tag.id = filter_link.tag_id
    WHERE filter_link.product_id = product.id
      AND lower(filter_tag.value) = lower($4)
      AND filter_tag.deleted_at IS NULL
  ))
  AND (json_array_length($5) = 0 OR EXISTS (
    SELECT 1
    FROM product_variants filter_variant
    JOIN variant_prices filter_price
      ON filter_price.variant_id = filter_variant.id
    JOIN variant_option_values filter_choice
      ON filter_choice.variant_id = filter_variant.id
    JOIN product_options filter_option
      ON filter_option.id = filter_choice.option_id
    JOIN product_product_options filter_product_option
      ON filter_product_option.product_id = product.id
     AND filter_product_option.product_option_id = filter_option.id
    JOIN product_option_values filter_value
      ON filter_value.id = filter_choice.option_value_id
     AND filter_value.option_id = filter_choice.option_id
    WHERE filter_variant.product_id = product.id
      AND filter_variant.deleted_at IS NULL
      AND filter_price.currency_code = $1
      AND filter_option.deleted_at IS NULL
      AND filter_product_option.deleted_at IS NULL
      AND filter_value.deleted_at IS NULL
      AND filter_choice.option_value_id IN (
        SELECT value FROM json_each($5)
      )
  ))
''')
  Future<Result<int, SqlxError>> countPublished(
    String currencyCode,
    String? collectionHandle,
    String? categoryHandle,
    String? tag,
    String optionValueIdsJson,
  );
}
