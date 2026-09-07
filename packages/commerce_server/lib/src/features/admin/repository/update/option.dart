import 'package:dust_dart/db.dart';

part 'option.g.dart';

/// Product-option writes behind the protected merchant route.
@SqlxDao()
abstract final class AdminProductOptionUpdateRepository {
  /// Binds option mutations to [db].
  const factory AdminProductOptionUpdateRepository(DatabaseExecutor db) =
      _$AdminProductOptionUpdateRepository;

  /// Counts variants that would lose their selected value if it were removed.
  @Query(r'''
SELECT count(*)
FROM variant_option_values selection
JOIN product_variants variant ON variant.id = selection.variant_id
JOIN product_option_values value ON value.id = selection.option_value_id
WHERE selection.option_id = $1
  AND value.value = $2
  AND variant.deleted_at IS NULL
''')
  Future<Result<int, SqlxError>> selectionCount(
    String optionId,
    String value,
  );

  /// Renames an option unless another global option already uses the title.
  @Query(r'''
UPDATE product_options
SET title = trim($2)
WHERE id = $1
  AND deleted_at IS NULL
  AND (is_exclusive = 1 OR NOT EXISTS (
    SELECT 1 FROM product_options sibling
    WHERE sibling.title = trim($2)
      AND sibling.id <> $1
      AND sibling.is_exclusive = 0
      AND sibling.deleted_at IS NULL
  ))
''')
  Future<Result<ExecResult, SqlxError>> updateTitle(
    String optionId,
    String title,
  );

  /// Moves an existing active value to its requested display rank.
  @Query(r'''
UPDATE product_option_values
SET rank = $3
WHERE option_id = $1 AND value = $2 AND deleted_at IS NULL
''')
  Future<Result<ExecResult, SqlxError>> rankValue(
    String optionId,
    String value,
    int rank,
  );

  /// Resolves an active global value after ranking or insertion.
  @Query(r'''
SELECT id
FROM product_option_values
WHERE option_id = $1 AND value = $2 AND deleted_at IS NULL
''')
  Future<Result<String?, SqlxError>> valueId(String optionId, String value);

  /// Adds one stable value with a server-owned identifier.
  @Query(r'''
INSERT INTO product_option_values (id, option_id, value, rank)
VALUES ($1, $2, $3, $4)
''')
  Future<Result<ExecResult, SqlxError>> insertValue(
    String id,
    String optionId,
    String value,
    int rank,
  );

  /// Exposes a newly created value through the requested product link.
  @Query(r'''
INSERT INTO product_product_option_values
  (id, product_product_option_id, product_option_value_id)
SELECT $1, link.id, $4
FROM product_product_options link
WHERE link.product_id = $2
  AND link.product_option_id = $3
  AND link.deleted_at IS NULL
''')
  Future<Result<ExecResult, SqlxError>> insertAvailability(
    String id,
    String productId,
    String optionId,
    String valueId,
  );

  /// Retires an unused value while preserving its audit history.
  @Query(r'''
UPDATE product_option_values
SET deleted_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE option_id = $1 AND value = $2 AND deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM variant_option_values selection
    JOIN product_variants variant ON variant.id = selection.variant_id
    WHERE selection.option_value_id = product_option_values.id
      AND variant.deleted_at IS NULL
  )
''')
  Future<Result<ExecResult, SqlxError>> deleteValue(
    String optionId,
    String value,
  );
}
