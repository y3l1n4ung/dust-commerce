import 'package:commerce_server/src/features/cart/model/shipping.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// The cart's list queries.
@SqlxDao()
abstract final class CartListRepository {
  /// Binds the queries to [db].
  const factory CartListRepository(DatabaseExecutor db) = _$CartListRepository;

  /// The delivery options [regionId] offers, cheapest first.
  ///
  /// Scoped to the region in SQL. An option belonging to another region cannot
  /// be offered, and therefore cannot be chosen, without the handler having to
  /// remember to check.
  @Query(r'''
SELECT id AS option_id, name,
       json_object('amount', amount, 'currency_code', currency_code) AS amount
FROM shipping_options
WHERE region_id = $1
ORDER BY shipping_options.amount, id
''')
  Future<Result<List<ShippingMethodResponse>, SqlxError>> shippingOptionsOf(
    String regionId,
  );

  /// One option, checked against the region that is allowed to use it.
  @Query(r'''
SELECT id AS option_id, name,
       json_object('amount', amount, 'currency_code', currency_code) AS amount
FROM shipping_options
WHERE id = $1 AND region_id = $2
''')
  Future<Result<ShippingMethodResponse?, SqlxError>> shippingOptionFor(
    String optionId,
    String regionId,
  );
}
