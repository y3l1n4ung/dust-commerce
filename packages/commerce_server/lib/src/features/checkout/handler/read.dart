import 'package:commerce_server/src/features/checkout/deps.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// The email a caller proves, or a rejection saying it is required.
Result<String, Rejection> emailOf(Request request) {
  final email = request.requestedUri.queryParameters['email'];
  if (email == null || email.isEmpty) {
    return const Err(
      Rejection.badRequest('An email is required to read an order'),
    );
  }
  return Ok(email);
}

/// `GET /orders/{id}` — one order.
///
/// Scoped by the email the caller proves. Without that an order id, which
/// travels in emails and browser history, would be enough to read somebody's
/// address and what they bought. A mismatch answers 404, not 403: confirming
/// that an id exists is itself the leak.
Future<Result<Order, Rejection>> readOrderHandler(Request request) async {
  final id = pathParametersOf(request)['id'];
  if (id == null || id.isEmpty) {
    return const Err(Rejection.badRequest('An order id is required'));
  }

  final email = emailOf(request);
  if (email case Err(:final error)) return Err(error);
  final asked = (email as Ok<String, Rejection>).value;

  final state = await checkoutDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CheckoutDeps, Rejection>).value;

  final result = await loadOrder(deps.reads, id);

  return switch (result) {
    Ok(value: final order?) when order.email == asked => Ok(order),
    Ok() => Err(Rejection.notFound('Order "$id"')),
    Err() => const Err(Rejection.internal()),
  };
}
