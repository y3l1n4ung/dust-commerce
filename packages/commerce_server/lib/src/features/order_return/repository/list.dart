import 'package:commerce_server/src/features/order_return/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// Public return-reason list queries.
@SqlxDao()
abstract final class OrderReturnListRepository {
  /// Binds reason discovery to [db].
  const factory OrderReturnListRepository(DatabaseExecutor db) =
      _$OrderReturnListRepository;

  /// Counts every active reason independently from page size.
  @Query(r'''
SELECT count(*)
FROM return_reasons
WHERE deleted_at IS NULL
''')
  Future<Result<int, SqlxError>> countReasons();

  /// Lists active reasons with parents before children in stable groups.
  @Query(r'''
SELECT id, value, label, description, parent_return_reason_id,
       created_at, updated_at
FROM return_reasons
WHERE deleted_at IS NULL
ORDER BY COALESCE(parent_return_reason_id, id),
         CASE WHEN parent_return_reason_id IS NULL THEN 0 ELSE 1 END,
         lower(label), id
LIMIT $1 OFFSET $2
''')
  Future<Result<List<ReturnReasonResponse>, SqlxError>> reasons(
    int limit,
    int offset,
  );
}
