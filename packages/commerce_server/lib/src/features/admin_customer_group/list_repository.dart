import 'package:commerce_server/src/features/admin_customer_group/list_response.dart';
import 'package:dust_dart/db.dart';

part 'list_repository.g.dart';

/// Protected merchant customer-group list persistence.
@SqlxDao()
abstract final class AdminCustomerGroupListRepository {
  /// Binds immutable customer-group reads to [db].
  const factory AdminCustomerGroupListRepository(DatabaseExecutor db) =
      _$AdminCustomerGroupListRepository;

  /// Lists exact columns requested by Medusa's customer-group table.
  @Query(r'''
SELECT customer_group.id,
       customer_group.name,
       COALESCE((
         SELECT json_group_array(json_object('id', member.customer_id))
         FROM (
           SELECT membership.customer_id
           FROM customer_group_customers membership
           JOIN customers customer ON customer.id = membership.customer_id
           WHERE membership.customer_group_id = customer_group.id
             AND membership.deleted_at IS NULL
             AND customer.deleted_at IS NULL
           ORDER BY membership.created_at, membership.id
         ) member
       ), '[]') AS customers_json,
       customer_group.created_at,
       customer_group.updated_at
FROM customer_groups customer_group
WHERE customer_group.deleted_at IS NULL
  AND ($1 = '' OR lower(customer_group.id) LIKE '%' || lower($1) || '%'
       OR lower(customer_group.name) LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR customer_group.created_at > $2)
  AND ($3 = '' OR customer_group.created_at >= $3)
  AND ($4 = '' OR customer_group.created_at < $4)
  AND ($5 = '' OR customer_group.created_at <= $5)
  AND ($6 = '' OR customer_group.updated_at > $6)
  AND ($7 = '' OR customer_group.updated_at >= $7)
  AND ($8 = '' OR customer_group.updated_at < $8)
  AND ($9 = '' OR customer_group.updated_at <= $9)
ORDER BY
  CASE WHEN $10 = 'name' THEN lower(customer_group.name) END ASC,
  CASE WHEN $10 = '-name' THEN lower(customer_group.name) END DESC,
  CASE WHEN $10 = 'created_at' THEN customer_group.created_at END ASC,
  CASE WHEN $10 = '-created_at' THEN customer_group.created_at END DESC,
  CASE WHEN $10 = 'updated_at' THEN customer_group.updated_at END ASC,
  CASE WHEN $10 = '-updated_at' THEN customer_group.updated_at END DESC,
  customer_group.created_at DESC,
  customer_group.id
LIMIT $11 OFFSET $12
''')
  Future<Result<List<AdminCustomerGroupResponse>, SqlxError>> list(
    String query,
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

  /// Counts rows through the same search and date-filter boundary.
  @Query(r'''
SELECT count(*)
FROM customer_groups customer_group
WHERE customer_group.deleted_at IS NULL
  AND ($1 = '' OR lower(customer_group.id) LIKE '%' || lower($1) || '%'
       OR lower(customer_group.name) LIKE '%' || lower($1) || '%')
  AND ($2 = '' OR customer_group.created_at > $2)
  AND ($3 = '' OR customer_group.created_at >= $3)
  AND ($4 = '' OR customer_group.created_at < $4)
  AND ($5 = '' OR customer_group.created_at <= $5)
  AND ($6 = '' OR customer_group.updated_at > $6)
  AND ($7 = '' OR customer_group.updated_at >= $7)
  AND ($8 = '' OR customer_group.updated_at < $8)
  AND ($9 = '' OR customer_group.updated_at <= $9)
''')
  Future<Result<int, SqlxError>> count(
    String query,
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
