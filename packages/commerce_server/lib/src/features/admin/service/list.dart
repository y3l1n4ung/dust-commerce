import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Lists one bounded page of merchant-visible catalogue rows.
Future<Result<AdminProductListResponse, SqlxError>> listAdminProducts(
  AdminProductRepository products, {
  required String query,
  required int limit,
  required int offset,
}) async {
  final normalized = query.trim();
  final page = await products.list(normalized, limit, offset);
  if (page case Err(:final error)) return Err(error);

  final total = await products.count(normalized);
  if (total case Err(:final error)) return Err(error);

  return Ok(AdminProductListResponse(
    products: (page as Ok<List<AdminProductResponse>, SqlxError>).value,
    count: (total as Ok<int, SqlxError>).value,
    limit: limit,
    offset: offset,
  ));
}
