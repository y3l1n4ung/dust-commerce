import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

/// `GET /orders` — the orders placed by one email address.
Handler listOrdersHandler(
  CheckoutListRepository lists,
  CheckoutReadRepository reads,
) {
  return (Request request) async {
    final email = request.requestedUri.queryParameters['email'];
    if (email == null || email.isEmpty) {
      return badRequest('An email is required to list orders');
    }

    final found = await lists.ordersFor(email);
    if (found case Err()) return internalError();

    final orders = <Map<String, Object?>>[];
    for (final row in (found as Ok<List<OrderRow>, SqlxError>).value) {
      final loaded = await loadOrder(reads, row.id);
      if (loaded case Err()) return internalError();
      final order = (loaded as Ok<Order?, SqlxError>).value;
      if (order != null) orders.add(order.toJson());
    }

    return jsonResponse({'orders': orders, 'count': orders.length});
  };
}
