import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /orders/{id}` — one order.
///
/// Scoped by the email the caller proves with `?email=`. Without that an order
/// id, which travels in emails and browser history, would be enough to read
/// somebody's address and what they bought.
Handler getOrderHandler(CheckoutRepository repository) {
  return (Request request) async {
    final id = pathParametersOf(request)['id'];
    if (id == null || id.isEmpty) return badRequest('An order id is required');

    final email = request.requestedUri.queryParameters['email'];
    if (email == null || email.isEmpty) {
      return badRequest('An email is required to read an order');
    }

    final result = await loadOrder(repository, id);

    return switch (result) {
      Ok(value: final order?) when order.email == email =>
        jsonResponse(order.toJson()),
      Ok() => notFound('Order "$id"'),
      Err() => internalError(),
    };
  };
}
