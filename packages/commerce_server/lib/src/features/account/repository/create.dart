import 'package:dust_dart/db.dart';

part 'create.g.dart';

/// Writes for customer registration and session creation.
@SqlxDao()
abstract final class AccountCreateRepository {
  /// Binds the queries to [db].
  const factory AccountCreateRepository(DatabaseExecutor db) =
      _$AccountCreateRepository;

  /// Creates the customer actor. A uniqueness race becomes zero rows.
  @Query(r'''
INSERT INTO customers (id, email, first_name, last_name, phone, has_account)
VALUES ($1, $2, $3, $4, $5, 1)
ON CONFLICT DO NOTHING
''')
  Future<Result<ExecResult, SqlxError>> insertCustomer(
    String id,
    String email,
    String? firstName,
    String? lastName,
    String? phone,
  );

  /// Creates the provider-independent auth identity.
  @Query(r'''
INSERT INTO auth_identity (id, app_metadata) VALUES ($1, $2)
''')
  Future<Result<ExecResult, SqlxError>> insertAuthIdentity(
    String id,
    String appMetadata,
  );

  /// Attaches the email/password provider and its Argon2id PHC value.
  @Query(r'''
INSERT INTO provider_identity
  (id, entity_id, provider, auth_identity_id, provider_metadata)
VALUES ($1, $2, 'emailpass', $3, $4)
''')
  Future<Result<ExecResult, SqlxError>> insertProviderIdentity(
    String id,
    String email,
    String authIdentityId,
    String providerMetadata,
  );

  /// Stores only an opaque token's fingerprint.
  @Query(r'''
INSERT INTO auth_tokens (token_hash, auth_identity_id, expires_at)
VALUES ($1, $2, $3)
''')
  Future<Result<ExecResult, SqlxError>> insertToken(
    String tokenHash,
    String authIdentityId,
    String expiresAt,
  );
}
