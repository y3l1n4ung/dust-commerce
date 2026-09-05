import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:dust_server/server.dart';

/// `DELETE /auth/session` — revoke the current bearer token.
Future<Result<Map<String, bool>, Rejection>> signOutHandler(
  Request request,
) async {
  final deps = await request.state<AccountDeps>();
  final actor = await request.extract(const CustomerAuth());
  final revoked = await signOut(deps.deletes, actor.token);
  if (revoked case Err()) return const Err(Rejection.internal());
  return const Ok({'success': true});
}
