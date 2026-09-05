import 'package:commerce_server/src/features/catalog/deps.dart';
import 'package:commerce_server/src/features/catalog/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /products` — a page of the published catalogue.
Future<Result<ProductPageView, Rejection>> listProductsHandler(
  Request request,
) async {
  final state = await catalogDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CatalogDeps, Rejection>).value;

  final paging = pagingOf(request);
  final result = await listProducts(
    deps.lists,
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
}
