import 'package:dust_dart/db.dart';

part 'update.g.dart';

/// Product writes kept separate from merchant reads and auth persistence.
@SqlxDao()
abstract final class AdminProductUpdateRepository {
  /// Binds product mutations to [db].
  const factory AdminProductUpdateRepository(DatabaseExecutor db) =
      _$AdminProductUpdateRepository;

  /// Replaces supported general fields when no active product owns [handle].
  ///
  /// The single statement makes handle conflict detection race-safe under
  /// SQLite's serialized writer lock. Database triggers own `updated_at`.
  @Query(r'''
UPDATE products
SET title = trim($2),
    handle = $3,
    subtitle = nullif(trim($4), ''),
    material = nullif(trim($5), ''),
    description = nullif(trim($6), ''),
    discountable = $7,
    status = $8
WHERE id = $1
  AND deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM products other
    WHERE other.handle = $3
      AND other.id <> $1
      AND other.deleted_at IS NULL
  )
''')
  Future<Result<ExecResult, SqlxError>> updateGeneral(
    String id,
    String title,
    String handle,
    String? subtitle,
    String? material,
    String? description,
    int discountable,
    String status,
  );
}
