import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// The reads that list somebody's orders.
@SqlxDao()
abstract final class CheckoutListRepository {
  /// Binds the queries to [db].
  const factory CheckoutListRepository(DatabaseExecutor db) =
      _$CheckoutListRepository;

  /// The orders placed by one email address, newest first.
  ///
  /// Scoped by email in SQL. A history endpoint that filters in Dart is one
  /// forgotten line away from showing somebody else's orders.
  @Query(r'''
SELECT o.id, o.email, o.customer_id, o.currency_code, o.subtotal,
       o.shipping_total, o.discount_total, o.tax, o.total, o.status,
       o.payment_status, o.placed_at, o.region_id,
       o.shipping_option_id, o.shipping_name,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries
FROM orders o
JOIN regions r ON r.id = o.region_id
WHERE o.email = $1
ORDER BY o.placed_at DESC, o.id DESC
''')
  Future<Result<List<OrderRow>, SqlxError>> ordersFor(String email);
}
