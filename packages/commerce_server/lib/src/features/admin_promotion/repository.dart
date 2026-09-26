import 'package:commerce_server/src/features/admin_promotion/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Read-only promotion queries used by the protected Admin list.
@SqlxDao()
abstract final class AdminPromotionRepository {
  /// Binds promotion queries to [db].
  const factory AdminPromotionRepository(DatabaseExecutor db) =
      _$AdminPromotionRepository;

  /// Lists active promotions with Medusa's table columns.
  @Query(r'''
SELECT id, code, type, value, currency_code, starts_at, ends_at, usage_limit,
       usage_count, created_at, updated_at, 0 AS is_automatic,
       CASE
         WHEN starts_at IS NOT NULL
              AND starts_at > strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
           THEN 'scheduled'
         WHEN (ends_at IS NOT NULL
               AND ends_at < strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
              OR (usage_limit IS NOT NULL AND usage_count >= usage_limit)
           THEN 'expired'
         ELSE 'active'
       END AS status
FROM promotions
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(code) LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR created_at > $2)
  AND ($3 = '' OR created_at >= $3)
  AND ($4 = '' OR created_at < $4)
  AND ($5 = '' OR created_at <= $5)
  AND ($6 = '' OR updated_at > $6)
  AND ($7 = '' OR updated_at >= $7)
  AND ($8 = '' OR updated_at < $8)
  AND ($9 = '' OR updated_at <= $9)
ORDER BY
  CASE WHEN $10 = 'created_at' THEN created_at END ASC,
  CASE WHEN $10 = '-created_at' THEN created_at END DESC,
  CASE WHEN $10 = 'updated_at' THEN updated_at END ASC,
  CASE WHEN $10 = '-updated_at' THEN updated_at END DESC,
  id ASC
LIMIT $11 OFFSET $12
''')
  Future<Result<List<AdminPromotionResponse>, SqlxError>> list(
    String query,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
    String order,
    int limit,
    int offset,
  );

  /// Counts active promotions matching the same filter set.
  @Query(r'''
SELECT count(*)
FROM promotions
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(code) LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR created_at > $2)
  AND ($3 = '' OR created_at >= $3)
  AND ($4 = '' OR created_at < $4)
  AND ($5 = '' OR created_at <= $5)
  AND ($6 = '' OR updated_at > $6)
  AND ($7 = '' OR updated_at >= $7)
  AND ($8 = '' OR updated_at < $8)
  AND ($9 = '' OR updated_at <= $9)
''')
  Future<Result<int, SqlxError>> count(
    String query,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
  );
}
