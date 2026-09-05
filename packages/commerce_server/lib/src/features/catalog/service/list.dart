import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Lists complete published product responses in [currencyCode].
Future<Result<ProductPageResponse, SqlxError>> listProducts(
  CatalogListRepository lists, {
  required String currencyCode,
  int limit = 20,
  int offset = 0,
}) async {
  final page = await lists.listPublished(currencyCode, limit, offset);
  if (page case Err(:final error)) return Err(error);

  final total = await lists.countPublished();
  if (total case Err(:final error)) return Err(error);

  final products = (page as Ok<List<ProductResponse>, SqlxError>).value;
  return Ok(ProductPageResponse(
    products: products,
    count: products.length,
    total: (total as Ok<int, SqlxError>).value,
    limit: limit,
    offset: offset,
  ));
}
