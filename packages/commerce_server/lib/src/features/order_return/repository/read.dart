import 'package:commerce_server/src/features/order_return/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// SQL reads used to validate and return customer return requests.
@SqlxDao()
abstract final class OrderReturnReadRepository {
  /// Binds return reads to [db].
  const factory OrderReturnReadRepository(DatabaseExecutor db) =
      _$OrderReturnReadRepository;

  /// Completed-order facts, scoped to the authenticated customer in SQL.
  @Query(r'''
SELECT status, payment_status
FROM orders
WHERE id = $1 AND customer_id = $2 AND deleted_at IS NULL
''')
  Future<Result<OrderReturnCandidate?, SqlxError>> order(
    String orderId,
    String customerId,
  );

  /// Frozen bought quantity and quantity already claimed by active returns.
  @Query(r'''
SELECT item.id, item.quantity,
       COALESCE((
         SELECT SUM(returned.quantity)
         FROM return_items returned
         JOIN return_requests request ON request.id = returned.return_id
         WHERE returned.order_item_id = item.id
           AND request.status <> 'canceled'
           AND request.deleted_at IS NULL
       ), 0) AS requested_quantity
FROM order_items item
WHERE item.order_id = $1 AND item.id = $2
''')
  Future<Result<OrderReturnItemCandidate?, SqlxError>> item(
    String orderId,
    String itemId,
  );

  /// Active reason identifier, or absent when retired or unknown.
  @Query(r'''
SELECT id FROM return_reasons WHERE id = $1 AND deleted_at IS NULL
''')
  Future<Result<String?, SqlxError>> reason(String reasonId);

  /// Minimal response for one newly persisted request.
  @Query(r'''
SELECT request.id, request.display_id, request.order_id, request.status,
       SUM(item.quantity) AS item_quantity, request.requested_at
FROM return_requests request
JOIN return_items item ON item.return_id = request.id
WHERE request.id = $1 AND request.deleted_at IS NULL
GROUP BY request.id, request.display_id, request.order_id,
         request.status, request.requested_at
''')
  Future<Result<OrderReturnResponse?, SqlxError>> response(String returnId);
}
