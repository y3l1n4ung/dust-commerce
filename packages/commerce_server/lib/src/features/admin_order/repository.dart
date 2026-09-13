import 'package:commerce_server/src/features/admin_order/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Protected merchant order-list persistence.
@SqlxDao()
abstract final class AdminOrderRepository {
  /// Binds immutable order reads to [db].
  const factory AdminOrderRepository(DatabaseExecutor db) =
      _$AdminOrderRepository;

  /// Lists the exact columns consumed by Medusa's merchant order table.
  @Query(r'''
SELECT order_row.id,
       order_row.display_id,
       order_row.created_at,
       order_row.updated_at,
       order_row.email,
       coalesce(
         nullif(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')), ''),
         order_row.email
       ) AS customer_name,
       order_row.status,
       order_row.payment_status,
       'not_fulfilled' AS fulfillment_status,
       order_row.total,
       order_row.currency_code,
       shipping.country_code,
       sales_channel.name AS sales_channel_name
FROM orders order_row
LEFT JOIN customers customer
  ON customer.id = order_row.customer_id AND customer.deleted_at IS NULL
LEFT JOIN order_addresses shipping
  ON shipping.order_id = order_row.id AND shipping.kind = 'shipping'
LEFT JOIN order_sales_channels channel_link
  ON channel_link.order_id = order_row.id
LEFT JOIN sales_channels sales_channel
  ON sales_channel.id = channel_link.sales_channel_id
WHERE order_row.deleted_at IS NULL
  AND ($1 = '' OR lower(order_row.id) LIKE '%' || lower($1) || '%'
       OR cast(order_row.display_id AS TEXT) LIKE '%' || $1 || '%'
       OR lower(order_row.email) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.first_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.last_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')))
          LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR instr(',' || $2 || ',',
                        ',' || order_row.status || ',') > 0)
  AND ($3 = '' OR instr(',' || $3 || ',',
                        ',' || order_row.region_id || ',') > 0)
  AND ($4 = '' OR instr(',' || $4 || ',',
                        ',' || channel_link.sales_channel_id || ',') > 0)
  AND ($5 = '' OR order_row.created_at > $5)
  AND ($6 = '' OR order_row.created_at >= $6)
  AND ($7 = '' OR order_row.created_at < $7)
  AND ($8 = '' OR order_row.created_at <= $8)
  AND ($9 = '' OR order_row.updated_at > $9)
  AND ($10 = '' OR order_row.updated_at >= $10)
  AND ($11 = '' OR order_row.updated_at < $11)
  AND ($12 = '' OR order_row.updated_at <= $12)
ORDER BY
  CASE WHEN $13 = 'display_id' THEN order_row.display_id END ASC,
  CASE WHEN $13 = '-display_id' THEN order_row.display_id END DESC,
  CASE WHEN $13 = 'created_at' THEN order_row.created_at END ASC,
  CASE WHEN $13 = '-created_at' THEN order_row.created_at END DESC,
  CASE WHEN $13 = 'updated_at' THEN order_row.updated_at END ASC,
  CASE WHEN $13 = '-updated_at' THEN order_row.updated_at END DESC,
  order_row.display_id DESC
LIMIT $14 OFFSET $15
''')
  Future<Result<List<AdminOrderResponse>, SqlxError>> list(
    String query,
    String statuses,
    String regionIds,
    String salesChannelIds,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
    String order,
    int limit,
    int offset,
  );

  /// Counts rows with the same search and filter boundary.
  @Query(r'''
SELECT count(*)
FROM orders order_row
LEFT JOIN customers customer
  ON customer.id = order_row.customer_id AND customer.deleted_at IS NULL
LEFT JOIN order_sales_channels channel_link
  ON channel_link.order_id = order_row.id
WHERE order_row.deleted_at IS NULL
  AND ($1 = '' OR lower(order_row.id) LIKE '%' || lower($1) || '%'
       OR cast(order_row.display_id AS TEXT) LIKE '%' || $1 || '%'
       OR lower(order_row.email) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.first_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.last_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')))
          LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR instr(',' || $2 || ',',
                        ',' || order_row.status || ',') > 0)
  AND ($3 = '' OR instr(',' || $3 || ',',
                        ',' || order_row.region_id || ',') > 0)
  AND ($4 = '' OR instr(',' || $4 || ',',
                        ',' || channel_link.sales_channel_id || ',') > 0)
  AND ($5 = '' OR order_row.created_at > $5)
  AND ($6 = '' OR order_row.created_at >= $6)
  AND ($7 = '' OR order_row.created_at < $7)
  AND ($8 = '' OR order_row.created_at <= $8)
  AND ($9 = '' OR order_row.updated_at > $9)
  AND ($10 = '' OR order_row.updated_at >= $10)
  AND ($11 = '' OR order_row.updated_at < $11)
  AND ($12 = '' OR order_row.updated_at <= $12)
''')
  Future<Result<int, SqlxError>> count(
    String query,
    String statuses,
    String regionIds,
    String salesChannelIds,
    String createdAfter,
    String createdFrom,
    String createdBefore,
    String createdTo,
    String updatedAfter,
    String updatedFrom,
    String updatedBefore,
    String updatedTo,
  );
}
