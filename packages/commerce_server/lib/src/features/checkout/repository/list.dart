import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:dust_dart/db.dart';

part 'list.g.dart';

/// The reads that list somebody's complete order responses.
@SqlxDao()
abstract final class CheckoutListRepository {
  /// Binds the queries to [db].
  const factory CheckoutListRepository(DatabaseExecutor db) =
      _$CheckoutListRepository;

  /// Complete orders owned by one authenticated customer, newest first.
  ///
  /// Ownership is scoped in SQL, and line/address aggregates make this one
  /// round trip rather than a header query followed by N order loads.
  @Query(r'''
SELECT o.id, o.email, o.customer_id, o.currency_code, o.subtotal,
       o.shipping_total, o.discount_total, o.tax, o.total, o.status,
       o.payment_status, o.placed_at, o.region_id,
       o.shipping_option_id, o.shipping_name,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries,
       coalesce((
         SELECT json_group_array(json_object(
           'id', i.id, 'variant_id', i.variant_id,
           'product_id', i.product_id, 'product_handle', i.product_handle,
           'thumbnail', i.thumbnail, 'title', i.title,
           'variant_title', i.variant_title,
           'unit_price', json_object(
             'amount', i.unit_amount, 'currency_code', i.currency_code
           ),
           'quantity', i.quantity
         ))
         FROM order_items i WHERE i.order_id = o.id ORDER BY i.rowid
       ), '[]') AS items_json,
       json_object(
         'first_name', shipping.first_name, 'last_name', shipping.last_name,
         'company', shipping.company,
         'line1', shipping.line1, 'line2', shipping.line2,
         'city', shipping.city, 'province', shipping.province,
         'postal_code', shipping.postal_code,
         'country_code', shipping.country_code, 'phone', shipping.phone
       ) AS shipping_address_json,
       json_object(
         'first_name', coalesce(billing.first_name, shipping.first_name),
         'last_name', coalesce(billing.last_name, shipping.last_name),
         'company', CASE WHEN billing.order_id IS NULL
                         THEN shipping.company ELSE billing.company END,
         'line1', coalesce(billing.line1, shipping.line1),
         'line2', CASE WHEN billing.order_id IS NULL
                       THEN shipping.line2 ELSE billing.line2 END,
         'city', coalesce(billing.city, shipping.city),
         'province', CASE WHEN billing.order_id IS NULL
                          THEN shipping.province ELSE billing.province END,
         'postal_code', coalesce(billing.postal_code, shipping.postal_code),
         'country_code', coalesce(billing.country_code, shipping.country_code),
         'phone', CASE WHEN billing.order_id IS NULL
                       THEN shipping.phone ELSE billing.phone END
       ) AS billing_address_json
FROM orders o
JOIN regions r ON r.id = o.region_id
JOIN order_addresses shipping
  ON shipping.order_id = o.id AND shipping.kind = 'shipping'
LEFT JOIN order_addresses billing
  ON billing.order_id = o.id AND billing.kind = 'billing'
WHERE o.customer_id = $1
ORDER BY o.placed_at DESC, o.id DESC
''')
  Future<Result<List<OrderResponse>, SqlxError>> ordersForCustomer(
    String customerId,
  );
}
