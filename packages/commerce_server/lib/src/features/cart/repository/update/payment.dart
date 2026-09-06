import 'package:dust_dart/db.dart';

part 'payment.g.dart';

/// Atomic writes for the payment provider selected on an active cart.
@SqlxDao()
abstract final class CartPaymentRepository {
  /// Binds payment-session writes to [db].
  const factory CartPaymentRepository(DatabaseExecutor db) =
      _$CartPaymentRepository;

  /// Retains one provider choice only while the cart is active.
  @Query(r'''
INSERT INTO cart_payment_sessions (cart_id, provider_id)
SELECT id, $2
FROM carts
WHERE id = $1 AND completed_at IS NULL AND deleted_at IS NULL
ON CONFLICT (cart_id) DO UPDATE SET provider_id = excluded.provider_id
''')
  Future<Result<ExecResult, SqlxError>> setPaymentSession(
    String cartId,
    String providerId,
  );
}
