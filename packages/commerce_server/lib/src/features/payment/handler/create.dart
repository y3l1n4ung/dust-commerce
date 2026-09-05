import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/checkout/handler/read.dart';
import 'package:commerce_server/src/features/payment/deps.dart';
import 'package:commerce_server/src/features/payment/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `POST /orders/{id}/payments` — start paying for an order.
///
/// A plain function, mounted as `post(authorizePaymentHandler)`, which is how
/// dust_server's examples are written and what a generated route would emit.
///
/// A customer order requires its owner; a guest order uses its email capability.
Future<Result<Order, Rejection>> authorizePaymentHandler(
  Request request,
) async {
  final orderId = pathParametersOf(request)['id'];
  if (orderId == null || orderId.isEmpty) {
    return const Err(Rejection.badRequest('An order id is required'));
  }

  final context = await request.extract(const Extension<CustomerContext>());
  final customer = context.authenticated;
  final email = customer == null
      ? emailOf(request)
      : Ok<String, Rejection>(customer.customer.email);
  if (email case Err(:final error)) return Err(error);

  final state = await paymentDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<PaymentDeps, Rejection>).value;

  final result = await authorizePayment(
    deps.orders,
    deps.reads,
    deps.writes,
    orderId: orderId,
    email: (email as Ok<String, Rejection>).value,
    customerId: customer?.customer.id,
    id: deps.clock.nextId(),
  );

  return switch (result) {
    Ok(value: (final order?, _)) => Ok(order),
    Ok(value: (_, AuthorizeFailure.noOrder)) =>
      Err(Rejection.notFound('Order "$orderId"')),
    Ok(value: (_, AuthorizeFailure.cancelled)) =>
      const Err(Rejection.conflict('A cancelled order cannot be paid for')),
    Ok(value: (_, AuthorizeFailure.alreadyStarted)) =>
      const Err(Rejection.conflict('A payment has already been started')),
    Ok() => const Err(Rejection.internal()),
    Err() => const Err(Rejection.internal()),
  };
}
