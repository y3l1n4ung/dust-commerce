import 'package:commerce_server/src/features/catalog/repository/catalog_repository.dart';
import 'package:commerce_server/src/features/catalog/repository/product_row.dart';
import 'package:commerce_server/src/features/catalog/service/assemble.dart';
import 'package:dust_dart/db.dart';
import 'package:commerce_shared/commerce_shared.dart';

/// One published product by [handle], with its variants in [currencyCode].
///
/// Returns `Ok(null)` when nothing matches. A missing product is an ordinary
/// answer to a question, not a failure of the query, and the handler decides
/// it is a 404.
Future<Result<Product?, SqlxError>> findProduct(
  CatalogRepository repository, {
  required String handle,
  required String currencyCode,
}) async {
  final found = await repository.findByHandle(handle);
  if (found case Err(:final error)) return Err(error);

  final row = (found as Ok<ProductRow?, SqlxError>).value;
  if (row == null) return const Ok(null);

  final variants = await repository.variantsOf(row.id, currencyCode);
  if (variants case Err(:final error)) return Err(error);

  return Ok(
    assembleProduct(
      row,
      (variants as Ok<List<VariantRow>, SqlxError>).value,
    ),
  );
}
