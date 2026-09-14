import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:dust_dart/db.dart';

part 'customer_read.g.dart';

/// Customer-scoped reads for complete order responses.
@SqlxDao()
abstract final class CheckoutCustomerReadRepository {
  /// Binds the ownership-scoped query to [db].
  const factory CheckoutCustomerReadRepository(DatabaseExecutor db) =
      _$CheckoutCustomerReadRepository;

  /// One complete order only when it belongs to [customerId].
  @Query(r'''
SELECT o.id, o.display_id, o.email, o.customer_id, o.currency_code, o.subtotal,
       o.shipping_total, o.discount_total, o.tax, o.total, o.status,
       o.payment_status, o.placed_at, o.region_id,
       o.shipping_option_id, o.shipping_name,
       payment.provider AS payment_provider, payment.amount AS payment_amount,
       payment.created_at AS payment_created_at,
       r.name AS region_name, r.tax_rate, r.tax_inclusive, r.countries,
       coalesce((
         SELECT json_group_array(json_object(
           'id', i.id, 'variant_id', i.variant_id,
           'product_id', i.product_id, 'product_handle', i.product_handle,
           'thumbnail', i.thumbnail, 'title', i.title,
           'variant_title', i.variant_title,
           'unit_price', json_object('amount', i.unit_amount,
                                     'currency_code', i.currency_code),
           'quantity', i.quantity,
           'detail', json_object(
             'delivered_quantity', CASE
               WHEN o.status = 'completed' AND o.payment_status = 'captured'
               THEN i.quantity ELSE 0 END,
             'return_requested_quantity', coalesce(returned.requested_quantity, 0),
             'return_received_quantity', coalesce(returned.received_quantity, 0),
             'return_dismissed_quantity', coalesce(returned.dismissed_quantity, 0)
           )
         ))
         FROM order_items i
         LEFT JOIN (
           SELECT item.order_item_id,
                  SUM(CASE WHEN request.status IN ('open', 'requested')
                    THEN item.quantity WHEN request.status = 'partially_received'
                    THEN item.quantity - item.received_quantity
                    ELSE 0 END) AS requested_quantity,
                  SUM(CASE WHEN request.status IN ('received', 'partially_received')
                    THEN item.received_quantity - item.damaged_quantity
                    ELSE 0 END) AS received_quantity,
                  SUM(CASE WHEN request.status IN ('received', 'partially_received')
                    THEN item.damaged_quantity ELSE 0 END) AS dismissed_quantity
           FROM return_items item
           JOIN return_requests request ON request.id = item.return_id
           WHERE request.status <> 'canceled' AND request.deleted_at IS NULL
           GROUP BY item.order_item_id
         ) returned ON returned.order_item_id = i.id
         WHERE i.order_id = o.id ORDER BY i.rowid
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
JOIN order_addresses shipping ON shipping.order_id = o.id AND shipping.kind = 'shipping'
LEFT JOIN order_addresses billing ON billing.order_id = o.id AND billing.kind = 'billing'
LEFT JOIN payment_collections payment ON payment.order_id = o.id AND payment.deleted_at IS NULL
WHERE o.id = $1 AND o.customer_id = $2
''')
  Future<Result<OrderResponse?, SqlxError>> findCustomerOrder(
    String id,
    String customerId,
  );
}
