import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /products/{handle}` — one published product.
///
/// A draft answers 404 rather than 403. Telling an anonymous caller that a
/// handle exists but is not theirs to see leaks the catalogue before launch,
/// and the service returning null for both is what makes that automatic.
Handler readProductHandler(
  CatalogReadRepository reads,
  CatalogListRepository lists,
) {
  return (Request request) async {
    final handle = pathParametersOf(request)['handle'];
    if (handle == null || handle.isEmpty) {
      return badRequest('A product handle is required');
    }

    final result = await findProduct(
      reads,
      lists,
      handle: handle,
      currencyCode: currencyOf(request),
    );

    return switch (result) {
      Ok(value: final product?) => jsonResponse(product.toJson()),
      Ok() => notFound('Product "$handle"'),
      Err() => internalError(),
    };
  };
}
