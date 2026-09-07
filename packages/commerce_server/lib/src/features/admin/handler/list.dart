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
  final statuses = _productStatuses(request);
  if (statuses case Err(:final error)) return Err(error);
  final tagIds = _tagIds(request);
  if (tagIds case Err(:final error)) return Err(error);
  final createdAt = _dateFilter(request, 'created_at');
  if (createdAt case Err(:final error)) return Err(error);
  final updatedAt = _dateFilter(request, 'updated_at');
  if (updatedAt case Err(:final error)) return Err(error);
  final order = AdminProductOrder.parse(
    request.requestedUri.queryParameters['order'] ?? '-created_at',
  );
  if (order case None()) {
    return const Err(Rejection.badRequest('Unknown product order'));
  }
  final result = await listAdminProducts(
    deps.products,
    query: query,
    statuses: (statuses as Ok<List<AdminProductLifecycle>, Rejection>).value,
    tagIds: (tagIds as Ok<List<String>, Rejection>).value,
    createdAt: (createdAt as Ok<AdminDateFilter, Rejection>).value,
    updatedAt: (updatedAt as Ok<AdminDateFilter, Rejection>).value,
    order: (order as Some<AdminProductOrder>).value,
    limit: paging.limit,
    offset: paging.offset,
  );
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err() => const Err(Rejection.internal()),
  };
}

Result<AdminDateFilter, Rejection> _dateFilter(
  Request request,
  String name,
) {
  final parsed = AdminDateFilter.parse(
    request.requestedUri.queryParameters[name] ?? '',
  );
  return switch (parsed) {
    Some(:final value) => Ok(value),
    None() => Err(Rejection.badRequest('Invalid $name filter')),
  };
}

Result<List<AdminProductLifecycle>, Rejection> _productStatuses(
  Request request,
) {
  final raw = request.requestedUri.queryParameters['status'] ?? '';
  if (raw.isEmpty) return const Ok([]);
  final statuses = <AdminProductLifecycle>[];
  for (final value in raw.split(',')) {
    final matches = AdminProductLifecycle.values.where(
      (status) => status.name == value,
    );
    if (matches.isEmpty) {
      return const Err(Rejection.badRequest('Unknown product status'));
    }
    if (!statuses.contains(matches.single)) statuses.add(matches.single);
  }
  return Ok(List.unmodifiable(statuses));
}

Result<List<String>, Rejection> _tagIds(Request request) {
  final raw = request.requestedUri.queryParameters['tag_id'] ?? '';
  if (raw.isEmpty) return const Ok([]);
  final ids = raw.split(',');
  final valid = RegExp(r'^[A-Za-z0-9_:-]{1,100}$');
  if (ids.length > 100 || ids.any((id) => !valid.hasMatch(id))) {
    return const Err(Rejection.badRequest('Invalid product tag ids'));
  }
  return Ok(List.unmodifiable(ids.toSet()));
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
