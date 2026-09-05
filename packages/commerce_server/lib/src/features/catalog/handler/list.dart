import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /products` — a page of the published catalogue.
///
/// Parses the request, calls one service, returns a typed view. It holds no
/// product rules, which is why it stays this short.
Endpoint<Result<ProductPageView, Rejection>> listProductsEndpoint(
  CatalogListRepository lists,
) {
  return (Request request) async {
    final paging = pagingOf(request);

    final result = await listProducts(
      lists,
      currencyCode: currencyOf(request),
      limit: paging.limit,
      offset: paging.offset,
    );

    return switch (result) {
      Ok(value: final page) => Ok(
          ProductPageView(
            products: page.products,
            count: page.products.length,
            total: page.total,
            limit: page.limit,
            offset: page.offset,
          ),
        ),
      Err() => const Err(Rejection.internal()),
    };
  };
}
