import 'package:dust_dart/db.dart';

part 'update.g.dart';

/// The writes that move a payment on.
@SqlxDao()
abstract final class PaymentUpdateRepository {
  /// Binds the queries to [db].
  const factory PaymentUpdateRepository(DatabaseExecutor db) =
      _$PaymentUpdateRepository;

  /// Captures an authorised payment, and only an authorised one.
  ///
  /// The status is in the WHERE clause, so capturing twice affects no rows
  /// rather than taking the money again. A zero row count is how the second
  /// attempt finds out, which is the same shape the stock reservation uses.
  @Query(r'''
UPDATE payment_collections
SET status = 'captured', captured_at = $2
WHERE id = $1 AND status = 'authorized'
''')
  Future<Result<ExecResult, SqlxError>> capture(String id, String capturedAt);

  /// Marks the order paid and complete.
  @Query(r'''
UPDATE orders
SET payment_status = 'captured', status = 'completed'
WHERE id = $1 AND status != 'cancelled'
''')
  Future<Result<ExecResult, SqlxError>> completeOrder(String orderId);
}
