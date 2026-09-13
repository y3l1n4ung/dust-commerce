import 'package:commerce_server/src/features/admin_return/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Protected merchant return-list persistence.
@SqlxDao()
abstract final class AdminReturnRepository {
  /// Binds return reads to [db].
  const factory AdminReturnRepository(DatabaseExecutor db) =
      _$AdminReturnRepository;

  /// Lists the exact fields consumed by Medusa's order-detail return action.
  @Query(r'''
SELECT request.id,
       request.order_id,
       request.display_id,
       request.status,
       request.no_notification,
       request.refund_amount,
       request.requested_at,
       request.received_at,
       request.canceled_at,
       request.created_at,
       request.updated_at,
       coalesce((
         SELECT json_group_array(json_object(
           'id', item.id,
           'order_item_id', item.order_item_id,
           'quantity', item.quantity,
           'received_quantity', item.received_quantity,
           'damaged_quantity', item.damaged_quantity,
           'reason_id', item.reason_id,
           'note', item.note
         ))
         FROM (
           SELECT * FROM return_items
           WHERE return_id = request.id
           ORDER BY created_at, id
         ) item
       ), '[]') AS items_json
FROM return_requests request
WHERE request.deleted_at IS NULL
  AND request.status IN ('requested', 'received', 'partially_received', 'canceled')
  AND ($1 = '' OR request.order_id = $1)
  AND ($2 = '' OR instr(',' || $2 || ',', ',' || request.status || ',') > 0)
ORDER BY request.requested_at DESC, request.id DESC
LIMIT $3 OFFSET $4
''')
  Future<Result<List<AdminReturnResponse>, SqlxError>> list(
    String orderId,
    String statuses,
    int limit,
    int offset,
  );

  /// Counts active rows using the same filter boundary.
  @Query(r'''
SELECT count(*)
FROM return_requests request
WHERE request.deleted_at IS NULL
  AND request.status IN ('requested', 'received', 'partially_received', 'canceled')
  AND ($1 = '' OR request.order_id = $1)
  AND ($2 = '' OR instr(',' || $2 || ',', ',' || request.status || ',') > 0)
''')
  Future<Result<int, SqlxError>> count(String orderId, String statuses);
}
