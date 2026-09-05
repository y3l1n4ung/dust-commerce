import 'package:commerce_server/src/features/cart/model.dart';
import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The reads that load one order.
@SqlxDao()
abstract final class CheckoutReadRepository {
  /// Binds the queries to [db].
  const factory CheckoutReadRepository(DatabaseExecutor db) =
      _$CheckoutReadRepository;

  /// One order with the region it was sold under.
  @Query(r'''
SELECT o.id, o.email, o.customer_id, o.currency_code, o.subtotal,
       o.shipping_total, o.discount_total, o.tax, o.total, o.status,
       o.payment_status, o.placed_at, o.region_id,
       o.shipping_option_id, o.shipping_name,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries
FROM orders o
JOIN regions r ON r.id = o.region_id
WHERE o.id = $1
''')
  Future<Result<OrderRow?, SqlxError>> findOrder(String id);

  /// The lines of an order.
  @Query(r'''
SELECT id, variant_id, product_id, title, variant_title,
       unit_amount, currency_code, quantity
FROM order_items
WHERE order_id = $1
ORDER BY rowid
''')
  Future<Result<List<LineItemRow>, SqlxError>> itemsOf(String orderId);

  /// The addresses recorded for an order.
  @Query(r'''
SELECT kind, first_name, last_name, line1, line2, city, province,
       postal_code, country_code, phone
FROM order_addresses
WHERE order_id = $1
''')
  Future<Result<List<OrderAddressRow>, SqlxError>> addressesOf(String orderId);
}
