import 'package:commerce_server/src/features/region/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Public selling-region queries.
@SqlxDao()
abstract final class SellingRegionRepository {
  /// Binds the queries to [db].
  const factory SellingRegionRepository(DatabaseExecutor db) =
      _$SellingRegionRepository;

  /// Lists active regions in stable display order.
  @Query(r'''
SELECT id, name, currency_code, tax_rate, tax_inclusive, countries
FROM regions
WHERE deleted_at IS NULL
ORDER BY name, id
''')
  Future<Result<List<SellingRegionResponse>, SqlxError>> list();
}
