// The row type is imported from the library that declares it rather than
// through a barrel: Dust resolves a DAO's row type from the libraries a file
// imports and does not follow an export.
import 'package:commerce_server/src/features/payment/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The reads that find a payment.
@SqlxDao()
abstract final class PaymentReadRepository {
  /// Binds the queries to [db].
  const factory PaymentReadRepository(DatabaseExecutor db) =
      _$PaymentReadRepository;

  /// The payment on an order, if one has been started.
  @Query(r'''
SELECT id, order_id, provider, amount, currency_code, status, captured_at
FROM payment_collections
WHERE order_id = $1
ORDER BY created_at DESC
LIMIT 1
''')
  Future<Result<PaymentRow?, SqlxError>> forOrder(String orderId);
}
