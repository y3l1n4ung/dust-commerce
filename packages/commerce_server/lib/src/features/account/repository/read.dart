import 'package:commerce_server/src/features/account/model.dart';
import 'package:dust_dart/db.dart';

part 'read.g.dart';

/// Account and session lookups.
@SqlxDao()
abstract final class AccountReadRepository {
  /// Binds the queries to [db].
  const factory AccountReadRepository(DatabaseExecutor db) =
      _$AccountReadRepository;

  /// Resolves email/password credentials without exposing provider metadata.
  @Query(r'''
SELECT a.id AS auth_identity_id,
       coalesce(CAST(json_extract(p.provider_metadata, '$.password') AS TEXT),
                '') AS password_hash
FROM provider_identity p
JOIN auth_identity a ON a.id = p.auth_identity_id
JOIN customers c
  ON c.id = CAST(json_extract(a.app_metadata, '$.customer_id') AS TEXT)
WHERE p.provider = 'emailpass'
  AND p.entity_id COLLATE NOCASE = $1
  AND p.deleted_at IS NULL
  AND a.deleted_at IS NULL
  AND c.deleted_at IS NULL
''')
  Future<Result<PasswordCredential?, SqlxError>> accountByEmail(String email);

  /// Resolves the active email/password credential for one customer id.
  @Query(r'''
SELECT a.id AS auth_identity_id,
       coalesce(CAST(json_extract(p.provider_metadata, '$.password') AS TEXT),
                '') AS password_hash
FROM provider_identity p
JOIN auth_identity a ON a.id = p.auth_identity_id
JOIN customers c
  ON c.id = CAST(json_extract(a.app_metadata, '$.customer_id') AS TEXT)
WHERE p.provider = 'emailpass'
  AND c.id = $1
  AND p.deleted_at IS NULL
  AND a.deleted_at IS NULL
  AND c.deleted_at IS NULL
''')
  Future<Result<PasswordCredential?, SqlxError>> credentialForCustomer(
    String customerId,
  );

  /// Resolves an unexpired token fingerprint to its customer actor.
  @Query(r'''
SELECT c.id,
       coalesce(c.email, '') AS email,
       c.first_name,
       c.last_name,
       c.phone
FROM auth_tokens t
JOIN auth_identity a ON a.id = t.auth_identity_id
JOIN customers c
  ON c.id = CAST(json_extract(a.app_metadata, '$.customer_id') AS TEXT)
WHERE t.token_hash = $1
  AND t.expires_at > $2
  AND a.deleted_at IS NULL
  AND c.deleted_at IS NULL
''')
  Future<Result<CustomerResponse?, SqlxError>> customerForToken(
    String tokenHash,
    String now,
  );
}
