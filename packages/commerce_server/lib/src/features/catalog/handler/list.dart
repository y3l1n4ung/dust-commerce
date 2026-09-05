import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /products` — a page of the published catalogue.
///
/// The handler parses the request, calls one service, and shapes the answer.
/// It holds no product rules, which is why it stays this short.
Handler listProductsHandler(CatalogListRepository lists) {
  return (Request request) async {
    final paging = pagingOf(request);
    final currency = currencyOf(request);

    final result = await listProducts(
      lists,
      currencyCode: currency,
      limit: paging.limit,
      offset: paging.offset,
    );

    return switch (result) {
      Ok(:final value) => jsonResponse({
          'products': value.products.map((it) => it.toJson()).toList(),
          'count': value.products.length,
          'total': value.total,
          'limit': value.limit,
          'offset': value.offset,
        }),
      Err() => internalError(),
    };
  };
}
