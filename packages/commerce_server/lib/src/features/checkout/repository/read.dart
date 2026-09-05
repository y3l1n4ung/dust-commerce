import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// The reads that load one complete order response.
@SqlxDao()
abstract final class CheckoutReadRepository {
  /// Binds the queries to [db].
  const factory CheckoutReadRepository(DatabaseExecutor db) =
      _$CheckoutReadRepository;

  /// One complete order, including frozen lines and addresses.
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
         'line1', shipping.line1, 'line2', shipping.line2,
         'city', shipping.city, 'province', shipping.province,
         'postal_code', shipping.postal_code,
         'country_code', shipping.country_code, 'phone', shipping.phone
       ) AS shipping_address_json,
       json_object(
         'first_name', coalesce(billing.first_name, shipping.first_name),
         'last_name', coalesce(billing.last_name, shipping.last_name),
         'line1', coalesce(billing.line1, shipping.line1),
         'line2', coalesce(billing.line2, shipping.line2),
         'city', coalesce(billing.city, shipping.city),
         'province', coalesce(billing.province, shipping.province),
         'postal_code', coalesce(billing.postal_code, shipping.postal_code),
         'country_code', coalesce(billing.country_code, shipping.country_code),
         'phone', coalesce(billing.phone, shipping.phone)
       ) AS billing_address_json
FROM orders o
JOIN regions r ON r.id = o.region_id
JOIN order_addresses shipping
  ON shipping.order_id = o.id AND shipping.kind = 'shipping'
LEFT JOIN order_addresses billing
  ON billing.order_id = o.id AND billing.kind = 'billing'
WHERE o.id = $1
''')
  Future<Result<OrderResponse?, SqlxError>> findOrder(String id);

  /// Existing order id for a cart, used to make checkout retry-safe.
  @Query(r'''
SELECT id FROM orders WHERE cart_id = $1 AND deleted_at IS NULL
''')
  Future<Result<String?, SqlxError>> orderIdForCart(String cartId);

  /// One complete order only when it belongs to [customerId].
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
         'line1', shipping.line1, 'line2', shipping.line2,
         'city', shipping.city, 'province', shipping.province,
         'postal_code', shipping.postal_code,
         'country_code', shipping.country_code, 'phone', shipping.phone
       ) AS shipping_address_json,
       json_object(
         'first_name', coalesce(billing.first_name, shipping.first_name),
         'last_name', coalesce(billing.last_name, shipping.last_name),
         'line1', coalesce(billing.line1, shipping.line1),
         'line2', coalesce(billing.line2, shipping.line2),
         'city', coalesce(billing.city, shipping.city),
         'province', coalesce(billing.province, shipping.province),
         'postal_code', coalesce(billing.postal_code, shipping.postal_code),
         'country_code', coalesce(billing.country_code, shipping.country_code),
         'phone', coalesce(billing.phone, shipping.phone)
       ) AS billing_address_json
FROM orders o
JOIN regions r ON r.id = o.region_id
JOIN order_addresses shipping
  ON shipping.order_id = o.id AND shipping.kind = 'shipping'
LEFT JOIN order_addresses billing
  ON billing.order_id = o.id AND billing.kind = 'billing'
WHERE o.id = $1 AND o.customer_id = $2
''')
  Future<Result<OrderResponse?, SqlxError>> findCustomerOrder(
    String id,
    String customerId,
  );
}
