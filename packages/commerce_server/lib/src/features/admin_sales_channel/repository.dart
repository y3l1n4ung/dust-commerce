import 'package:commerce_server/src/features/admin_sales_channel/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Read-only sales-channel discovery used by Admin order filters.
@SqlxDao()
abstract final class AdminSalesChannelRepository {
  /// Binds sales-channel list queries to [db].
  const factory AdminSalesChannelRepository(DatabaseExecutor db) =
      _$AdminSalesChannelRepository;

  /// Counts the same non-deleted sales-channel search result.
  @Query(r'''
SELECT count(*)
FROM sales_channels
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(name) LIKE '%' || lower($1) || '%')
''')
  Future<Result<int, SqlxError>> count(String query);

  /// Lists enabled and disabled choices for current and historical orders.
  @Query(r'''
SELECT id, name
FROM sales_channels
WHERE deleted_at IS NULL
  AND ($1 = '' OR lower(name) LIKE '%' || lower($1) || '%')
ORDER BY lower(name), id
LIMIT $2 OFFSET $3
''')
  Future<Result<List<AdminSalesChannelResponse>, SqlxError>> list(
    String query,
    int limit,
    int offset,
  );
}
