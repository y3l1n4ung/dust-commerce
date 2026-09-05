import 'package:commerce_server/src/features/catalog/repository/catalog_repository.dart';
import 'package:commerce_server/src/features/catalog/repository/product_row.dart';
import 'package:commerce_server/src/features/catalog/service/assemble.dart';
import 'package:dust_dart/db.dart';
import 'package:commerce_shared/commerce_shared.dart';

/// A page of the catalogue, and how many there are in total.
///
/// The total travels with the page because a storefront cannot render "page 3
/// of 7" without it, and asking for it separately is a second round trip for
/// something the first query already knows how to count.
final class ProductPage {
  /// Creates a [ProductPage].
  const ProductPage({
    required this.products,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// How many were asked for.
  final int limit;

  /// How many were skipped.
  final int offset;

  /// The products on this page.
  final List<Product> products;

  /// How many published products exist.
  final int total;
}

/// Lists published products, each with its variants priced in [currencyCode].
///
/// One query for the page and one per product for its variants. That is N+1
/// and it is deliberate at this size: the alternative is a join that returns
/// the product columns once per variant, and reassembling that in Dart costs
/// more than it saves until the catalogue is large enough to measure.
Future<Result<ProductPage, SqlxError>> listProducts(
  CatalogRepository repository, {
  required String currencyCode,
  int limit = 20,
  int offset = 0,
}) async {
  final page = await repository.listPublished(limit, offset);
  if (page case Err(:final error)) return Err(error);

  final total = await repository.countPublished();
  if (total case Err(:final error)) return Err(error);

  final products = <Product>[];
  for (final row in (page as Ok<List<ProductRow>, SqlxError>).value) {
    final variants = await repository.variantsOf(row.id, currencyCode);
    if (variants case Err(:final error)) return Err(error);
    products.add(
      assembleProduct(
        row,
        (variants as Ok<List<VariantRow>, SqlxError>).value,
      ),
    );
  }

  return Ok(
    ProductPage(
      products: products,
      total: (total as Ok<int, SqlxError>).value,
      limit: limit,
      offset: offset,
    ),
  );
}
