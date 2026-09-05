import 'package:commerce_server/src/features/catalog/deps.dart';
import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:commerce_server/src/features/catalog/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /products` — a page of the published catalogue.
Future<Result<ProductPageResponse, Rejection>> listProductsHandler(
  Request request,
) async {
  final state = await catalogDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<CatalogDeps, Rejection>).value;

  final paging = pagingOf(request);
  final result = await listProducts(
    deps.lists,
    deps.counts,
    currencyCode: currencyOf(request),
    collection: queryOptionOf(request, 'collection'),
    category: queryOptionOf(request, 'category'),
    tag: queryOptionOf(request, 'tag'),
    optionValueIds: queryValuesOf(request, 'optionValueIds'),
    limit: paging.limit,
    offset: paging.offset,
  );

  return switch (result) {
    Ok(value: final page) => Ok(page),
    Err() => const Err(Rejection.internal()),
  };
}
