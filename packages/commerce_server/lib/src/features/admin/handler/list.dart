import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/deps.dart';
import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /admin/products` — lists catalogue rows for a proven merchant.
Future<Result<AdminProductListResponse, Rejection>> listAdminProductsHandler(
  Request request,
) async {
  final state = await adminDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<AdminDeps, Rejection>).value;
  final paging = pagingOf(request);
  final query = request.requestedUri.queryParameters['q'] ?? '';
  final result = await listAdminProducts(
    deps.products,
    query: query,
    limit: paging.limit,
    offset: paging.offset,
  );
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err() => const Err(Rejection.internal()),
  };
}

/// `GET /admin/products/create-context` — active pricing currencies.
Future<Result<AdminProductCreateContext, Rejection>>
    readAdminProductCreateContextHandler(
  Request request,
) async {
  final state = await adminDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<AdminDeps, Rejection>).value;
  final result = await readAdminProductCreateContext(deps.productCreates);
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err() => const Err(Rejection.internal()),
  };
}
