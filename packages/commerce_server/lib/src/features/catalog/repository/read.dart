import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The catalogue's single-row reads.
@SqlxDao()
abstract final class CatalogReadRepository {
  /// Binds the queries to [db].
  const factory CatalogReadRepository(DatabaseExecutor db) =
      _$CatalogReadRepository;

  /// One published product by the handle the storefront routed on.
  @Query(r'''
SELECT id, title, handle, description, thumbnail, status
FROM products
WHERE handle = $1 AND status = 'published'
''')
  Future<Result<ProductRow?, SqlxError>> findByHandle(String handle);

  /// One variant with its price, for adding a line to a cart.
  @Query(r'''
SELECT v.id, v.product_id, v.title, v.sku, v.inventory_quantity,
       v.manage_inventory, v.allow_backorder,
       p.currency_code, p.amount
FROM product_variants v
JOIN variant_prices p ON p.variant_id = v.id
WHERE v.id = $1 AND p.currency_code = $2
''')
  Future<Result<VariantRow?, SqlxError>> findVariant(
    String variantId,
    String currencyCode,
  );
}
