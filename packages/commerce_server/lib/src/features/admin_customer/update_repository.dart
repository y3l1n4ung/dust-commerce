import 'package:dust_dart/db.dart';

part 'update_repository.g.dart';

/// Direct SQLx persistence for merchant customer profile replacement.
@SqlxDao()
abstract final class AdminCustomerUpdateRepository {
  /// Binds customer updates to [db].
  const factory AdminCustomerUpdateRepository(DatabaseExecutor db) =
      _$AdminCustomerUpdateRepository;

  /// Replaces contact fields while the account-email guard still matches.
  @Query(r'''
UPDATE OR IGNORE customers
SET email = CASE WHEN has_account = 1 THEN email ELSE $2 END,
    company_name = $3,
    first_name = $4,
    last_name = $5,
    phone = $6
WHERE id = $1
  AND deleted_at IS NULL
  AND (
    (has_account = 0 AND $2 IS NOT NULL) OR
    (has_account = 1 AND ($2 IS NULL OR email = $2))
  )
''')
  Future<Result<ExecResult, SqlxError>> update(
    String id,
    String? email,
    String? companyName,
    String? firstName,
    String? lastName,
    String? phone,
  );
}
