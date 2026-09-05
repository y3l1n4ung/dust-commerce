// Row types are imported from the library that declares them rather than
// through model/model.dart. Dust resolves a DAO's row type by looking in
// the libraries a file imports and does not follow an export barrel, so a
// barrel import fails the build with 'unsupported DAO result type'.
import 'package:commerce_server/src/features/cart/model/cart.dart';
import 'package:dust_dart/db.dart';

part 'create.g.dart';

/// The writes that start a cart.
@SqlxDao()
abstract final class CartCreateRepository {
  /// Binds the queries to [db].
  const factory CartCreateRepository(DatabaseExecutor db) =
      _$CartCreateRepository;

  /// Starts a cart in [regionId].
  @Query(r'''
INSERT INTO carts (id, region_id, customer_id, email, created_at)
VALUES ($1, $2, $3, $4, $5)
''')
  Future<Result<ExecResult, SqlxError>> createCart(
    String id,
    String regionId,
    String? customerId,
    String? email,
    String createdAt,
  );

  /// One region by id, for a storefront that has chosen one.
  @Query(r'''
SELECT id, name, currency_code, tax_rate, tax_inclusive, countries
FROM regions
WHERE id = $1
''')
  Future<Result<RegionRow?, SqlxError>> regionById(String id);

  /// The default region, for a storefront that has not chosen one.
  @Query(r'''
SELECT id, name, currency_code, tax_rate, tax_inclusive, countries
FROM regions
ORDER BY id
LIMIT 1
''')
  Future<Result<RegionRow?, SqlxError>> firstRegion();
}
