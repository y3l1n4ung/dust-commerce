import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:dust_server/server.dart';

/// `DELETE /auth/session` — revoke the current bearer token.
Future<Result<Map<String, bool>, Rejection>> signOutHandler(
  Request request,
) async {
  final bearer = await const BearerTokenExtractable().extract(request);
  if (bearer case Err(:final error)) return Err(error);
  final depsResult = await accountDeps(request);
  if (depsResult case Err(:final error)) return Err(error);
  final deps = (depsResult as Ok<AccountDeps, Rejection>).value;
  final token = (bearer as Ok<String, Rejection>).value;

  final authenticated = await authenticateToken(
    deps.reads,
    token,
    deps.clock.now(),
  );
  switch (authenticated) {
    case Err():
      return const Err(Rejection.internal());
    case Ok(value: null):
      return const Err(Rejection.unauthorized('Invalid or expired token'));
    case Ok():
      break;
  }

  final revoked = await signOut(deps.deletes, token);
  if (revoked case Err()) return const Err(Rejection.internal());
  return const Ok({'success': true});
}
