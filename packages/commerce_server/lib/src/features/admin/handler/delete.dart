import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/deps.dart';
import 'package:commerce_server/src/features/admin/extractor.dart';
import 'package:commerce_server/src/features/admin/service/service.dart';
import 'package:dust_server/server.dart';

/// `DELETE /auth/admin/session` — revokes the current admin bearer.
Future<Result<AdminSessionDeleted, Rejection>> adminSignOutHandler(
  Request request,
) async {
  final deps = await request.state<AdminDeps>();
  final actor = await request.extract(const Extension<AuthenticatedAdmin>());
  final revoked = await adminSignOut(deps.deletes, actor.token);
  if (revoked case Err()) return const Err(Rejection.internal());
  return const Ok(AdminSessionDeleted(success: true));
}
