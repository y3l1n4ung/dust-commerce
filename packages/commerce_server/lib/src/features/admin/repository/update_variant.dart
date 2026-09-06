import 'package:dust_dart/db.dart';

part 'update_variant.g.dart';

/// Variant writes kept behind the protected merchant boundary.
@SqlxDao()
abstract final class AdminVariantUpdateRepository {
  /// Binds variant mutations to [db].
  const factory AdminVariantUpdateRepository(DatabaseExecutor db) =
      _$AdminVariantUpdateRepository;

  /// Resolves an active option value owned by the requested product.
  @Query(r'''
SELECT value.id
FROM product_option_values value
JOIN product_options option ON option.id = value.option_id
WHERE option.product_id = $1
  AND option.id = $2
  AND value.value = $3
  AND option.deleted_at IS NULL
  AND value.deleted_at IS NULL
''')
  Future<Result<String?, SqlxError>> optionValueId(
    String productId,
    String optionId,
    String value,
  );

  /// Replaces detail fields unless another active variant owns the SKU.
  ///
  /// Inventory quantity is intentionally excluded; Medusa adjusts stock in a
  /// separate inventory operation. Database triggers own `updated_at`.
  @Query(r'''
UPDATE product_variants
SET title = trim($3),
    sku = nullif(trim($4), ''),
    barcode = nullif(trim($5), ''),
    manage_inventory = $6,
    allow_backorder = $7
WHERE id = $1
  AND product_id = $2
  AND deleted_at IS NULL
  AND ($4 IS NULL OR trim($4) = '' OR NOT EXISTS (
    SELECT 1
    FROM product_variants other
    WHERE other.sku = trim($4)
      AND other.id <> $1
      AND other.deleted_at IS NULL
  ))
''')
  Future<Result<ExecResult, SqlxError>> updateVariant(
    String variantId,
    String productId,
    String title,
    String? sku,
    String? barcode,
    int manageInventory,
    int allowBackorder,
  );

  /// Replaces one option selection while retaining its original created time.
  @Query(r'''
INSERT INTO variant_option_values (variant_id, option_id, option_value_id)
VALUES ($1, $2, $3)
ON CONFLICT (variant_id, option_id) DO UPDATE
SET option_value_id = excluded.option_value_id
''')
  Future<Result<ExecResult, SqlxError>> upsertOptionValue(
    String variantId,
    String optionId,
    String optionValueId,
  );
}
