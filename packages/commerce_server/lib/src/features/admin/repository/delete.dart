import 'package:dust_dart/db.dart';

part 'delete.g.dart';

/// Admin session revocation.
@SqlxDao()
abstract final class AdminDeleteRepository {
  /// Binds the query to [db].
  const factory AdminDeleteRepository(DatabaseExecutor db) =
      _$AdminDeleteRepository;

  /// Revokes one bearer token by its fingerprint.
  @Query(r'DELETE FROM auth_tokens WHERE token_hash = $1')
  Future<Result<ExecResult, SqlxError>> revokeToken(String tokenHash);
}
