import 'package:dust_dart/db.dart';

part 'delete.g.dart';

/// Session revocation.
@SqlxDao()
abstract final class AccountDeleteRepository {
  /// Binds the query to [db].
  const factory AccountDeleteRepository(DatabaseExecutor db) =
      _$AccountDeleteRepository;

  /// Revokes one bearer token by its fingerprint.
  @Query(r'DELETE FROM auth_tokens WHERE token_hash = $1')
  Future<Result<ExecResult, SqlxError>> revokeToken(String tokenHash);
}
