import 'package:commerce_server/src/features/admin_customer/model.dart';
import 'package:dust_dart/db.dart';

part 'repository.g.dart';

/// Protected merchant customer-list persistence.
@SqlxDao()
abstract final class AdminCustomerRepository {
  /// Binds immutable customer reads to [db].
  const factory AdminCustomerRepository(DatabaseExecutor db) =
      _$AdminCustomerRepository;

  /// Lists the exact columns consumed by Medusa's merchant customer table.
  @Query(r'''
SELECT customer.id,
       customer.email,
       customer.first_name,
       customer.last_name,
       customer.has_account,
       customer.created_at,
       customer.updated_at
FROM customers customer
WHERE customer.deleted_at IS NULL
  AND ($1 = '' OR lower(customer.id) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.email, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.company_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.first_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.last_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')))
          LIKE '%' || lower($1) || '%')
  AND ($2 = -1 OR customer.has_account = $2)
  AND ($3 = '' OR customer.created_at > $3)
  AND ($4 = '' OR customer.created_at >= $4)
  AND ($5 = '' OR customer.created_at < $5)
  AND ($6 = '' OR customer.created_at <= $6)
  AND ($7 = '' OR customer.updated_at > $7)
  AND ($8 = '' OR customer.updated_at >= $8)
  AND ($9 = '' OR customer.updated_at < $9)
  AND ($10 = '' OR customer.updated_at <= $10)
ORDER BY
  CASE WHEN $11 = 'email' THEN lower(customer.email) END ASC,
  CASE WHEN $11 = '-email' THEN lower(customer.email) END DESC,
  CASE WHEN $11 = 'first_name' THEN lower(customer.first_name) END ASC,
  CASE WHEN $11 = '-first_name' THEN lower(customer.first_name) END DESC,
  CASE WHEN $11 = 'last_name' THEN lower(customer.last_name) END ASC,
  CASE WHEN $11 = '-last_name' THEN lower(customer.last_name) END DESC,
  CASE WHEN $11 = 'has_account' THEN customer.has_account END ASC,
  CASE WHEN $11 = '-has_account' THEN customer.has_account END DESC,
  CASE WHEN $11 = 'created_at' THEN customer.created_at END ASC,
  CASE WHEN $11 = '-created_at' THEN customer.created_at END DESC,
  CASE WHEN $11 = 'updated_at' THEN customer.updated_at END ASC,
  CASE WHEN $11 = '-updated_at' THEN customer.updated_at END DESC,
  customer.created_at DESC,
  customer.id
LIMIT $12 OFFSET $13
''')
  Future<Result<List<AdminCustomerResponse>, SqlxError>> list(
    String query,
    int hasAccount,
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
FROM customers customer
WHERE customer.deleted_at IS NULL
  AND ($1 = '' OR lower(customer.id) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.email, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.company_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.first_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(coalesce(customer.last_name, '')) LIKE '%' || lower($1) || '%'
       OR lower(trim(coalesce(customer.first_name, '') || ' ' ||
                     coalesce(customer.last_name, '')))
          LIKE '%' || lower($1) || '%')
  AND ($2 = -1 OR customer.has_account = $2)
  AND ($3 = '' OR customer.created_at > $3)
  AND ($4 = '' OR customer.created_at >= $4)
  AND ($5 = '' OR customer.created_at < $5)
  AND ($6 = '' OR customer.created_at <= $6)
  AND ($7 = '' OR customer.updated_at > $7)
  AND ($8 = '' OR customer.updated_at >= $8)
  AND ($9 = '' OR customer.updated_at < $9)
  AND ($10 = '' OR customer.updated_at <= $10)
''')
  Future<Result<int, SqlxError>> count(
    String query,
    int hasAccount,
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
