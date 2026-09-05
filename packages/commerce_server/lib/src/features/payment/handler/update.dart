import 'package:commerce_server/src/features/checkout/handler/read.dart';
import 'package:commerce_server/src/features/payment/deps.dart';
import 'package:commerce_server/src/features/payment/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `POST /orders/{id}/payments/capture` — take the money.
///
/// Capturing twice is a 409 rather than a quiet success. A client retrying a
/// timed-out request deserves to be told the first one worked, and a silent
/// second capture is how somebody gets charged twice.
Future<Result<Order, Rejection>> capturePaymentHandler(Request request) async {
  final orderId = pathParametersOf(request)['id'];
  if (orderId == null || orderId.isEmpty) {
    return const Err(Rejection.badRequest('An order id is required'));
  }

  final email = emailOf(request);
  if (email case Err(:final error)) return Err(error);

  final state = await paymentDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<PaymentDeps, Rejection>).value;

  final result = await capturePayment(
    deps.database,
    orderId: orderId,
    email: (email as Ok<String, Rejection>).value,
    now: deps.clock.now(),
  );

  return switch (result) {
    Ok(value: (final order?, _)) => Ok(order),
    Ok(value: (_, CaptureFailure.noOrder)) =>
      Err(Rejection.notFound('Order "$orderId"')),
    Ok(value: (_, CaptureFailure.noPayment)) =>
      const Err(Rejection.conflict('No payment has been started')),
    Ok(value: (_, CaptureFailure.alreadyCaptured)) =>
      const Err(Rejection.conflict('This payment has already been captured')),
    Ok(value: (_, CaptureFailure.cancelled)) =>
      const Err(Rejection.conflict('A cancelled order cannot be paid for')),
    Ok() => const Err(Rejection.internal()),
    Err() => const Err(Rejection.internal()),
  };
}
