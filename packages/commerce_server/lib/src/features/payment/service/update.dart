import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/features/payment/model.dart';
import 'package:commerce_server/src/features/payment/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Why a payment could not be captured.
enum CaptureFailure {
  /// No order with that id, or not this caller's.
  noOrder,

  /// No payment has been started for it.
  noPayment,

  /// The payment was already captured.
  alreadyCaptured,

  /// The order was cancelled before the money moved.
  cancelled,
}

/// Captures the payment on [orderId], completing the order.
///
/// Both writes happen in one transaction: an order marked paid whose payment
/// row still says authorised, or the reverse, is a reconciliation problem
/// somebody discovers a month later.
///
/// Capture is conditional in SQL, so a second attempt affects no rows and is
/// told so rather than taking the money again.
Future<Result<(Order?, CaptureFailure?), SqlxError>> capturePayment(
  CommerceDatabase database, {
  required String orderId,
  required String email,
  required DateTime now,
}) async {
  return database.transaction((tx) async {
    final orders = CheckoutReadRepository(tx);
    final reads = PaymentReadRepository(tx);
    final writes = PaymentUpdateRepository(tx);

    final loaded = await loadOrder(orders, orderId);
    if (loaded case Err(:final error)) return Err(error);

    final order = (loaded as Ok<Order?, SqlxError>).value;
    if (order == null || order.email != email) {
      return const Ok((null, CaptureFailure.noOrder));
    }
    if (order.status == OrderStatus.cancelled) {
      return const Ok((null, CaptureFailure.cancelled));
    }

    final found = await reads.forOrder(orderId);
    if (found case Err(:final error)) return Err(error);
    final payment = (found as Ok<PaymentRow?, SqlxError>).value;
    if (payment == null) return const Ok((null, CaptureFailure.noPayment));

    final captured = await writes.capture(
      payment.id,
      now.toUtc().toIso8601String(),
    );
    if (captured case Err(:final error)) return Err(error);
    if ((captured as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
      return const Ok((null, CaptureFailure.alreadyCaptured));
    }

    final completed = await writes.completeOrder(orderId);
    if (completed case Err(:final error)) return Err(error);

    // The domain type says what the order became, rather than this rebuilding
    // it: Order.captured() already refuses a cancelled order, and one rule in
    // one place is one rule to get wrong.
    return Ok((order.captured(), null));
  });
}
