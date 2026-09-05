import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/account/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Revokes a raw bearer token by deleting only its fingerprint.
Future<Result<ExecResult, SqlxError>> signOut(
  AccountDeleteRepository deletes,
  String token,
) async {
  return deletes.revokeToken(await Tokens.fingerprint(token));
}
