import 'package:commerce_server/src/features/admin_order/detail_model.dart';
import 'package:dust_dart/db.dart';

part 'detail_repository.g.dart';

/// Protected persistence for one complete merchant order snapshot.
@SqlxDao()
abstract final class AdminOrderDetailRepository {
  /// Binds immutable order-detail reads to [db].
  const factory AdminOrderDetailRepository(DatabaseExecutor db) =
      _$AdminOrderDetailRepository;

  /// Selects only the fields required by the read-only Admin detail screen.
  @Query(r'''
SELECT order_row.id,
       order_row.display_id,
       order_row.email,
       coalesce(
         nullif(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')), ''),
         order_row.email
       ) AS customer_name,
       order_row.currency_code,
       order_row.subtotal,
       order_row.shipping_total,
       order_row.discount_total,
       order_row.tax,
       order_row.total,
       order_row.status,
       order_row.payment_status,
       'not_fulfilled' AS fulfillment_status,
       order_row.shipping_name,
       order_row.promotion_code,
       order_row.placed_at,
       order_row.created_at,
       order_row.updated_at,
       payment.provider AS payment_provider,
       payment.amount AS payment_amount,
       payment.status AS payment_record_status,
       payment.created_at AS payment_created_at,
       payment.captured_at AS payment_captured_at,
       coalesce((
         SELECT json_group_array(json_object(
           'id', item.id,
           'variant_id', item.variant_id,
           'product_id', item.product_id,
           'product_handle', item.product_handle,
           'thumbnail', item.thumbnail,
           'title', item.title,
           'variant_title', item.variant_title,
           'unit_amount', item.unit_amount,
           'currency_code', item.currency_code,
           'quantity', item.quantity,
           'created_at', item.created_at
         ))
         FROM (
           SELECT * FROM order_items
           WHERE order_id = order_row.id
           ORDER BY created_at, id
         ) item
       ), '[]') AS items_json,
       CASE WHEN shipping.order_id IS NULL THEN NULL ELSE json_object(
         'first_name', shipping.first_name,
         'last_name', shipping.last_name,
         'company', shipping.company,
         'line1', shipping.line1,
         'line2', shipping.line2,
         'city', shipping.city,
         'province', shipping.province,
         'postal_code', shipping.postal_code,
         'country_code', shipping.country_code,
         'phone', shipping.phone
       ) END AS shipping_address_json,
       CASE WHEN billing.order_id IS NULL THEN NULL ELSE json_object(
         'first_name', billing.first_name,
         'last_name', billing.last_name,
         'company', billing.company,
         'line1', billing.line1,
         'line2', billing.line2,
         'city', billing.city,
         'province', billing.province,
         'postal_code', billing.postal_code,
         'country_code', billing.country_code,
         'phone', billing.phone
       ) END AS billing_address_json
FROM orders order_row
LEFT JOIN customers customer
  ON customer.id = order_row.customer_id AND customer.deleted_at IS NULL
LEFT JOIN order_addresses shipping
  ON shipping.order_id = order_row.id AND shipping.kind = 'shipping'
LEFT JOIN order_addresses billing
  ON billing.order_id = order_row.id AND billing.kind = 'billing'
LEFT JOIN payment_collections payment
  ON payment.order_id = order_row.id AND payment.deleted_at IS NULL
WHERE order_row.id = $1 AND order_row.deleted_at IS NULL
''')
  Future<Result<AdminOrderDetailResponse?, SqlxError>> find(String id);
}
