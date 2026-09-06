import 'package:commerce_server/src/features/admin/extractor.dart';
import 'package:commerce_server/src/features/admin/model.dart';
import 'package:dust_server/server.dart';

/// `GET /admin/users/me` — returns the proven admin profile.
Future<Result<AdminUserResponse, Rejection>> readCurrentAdminHandler(
  Request request,
) async {
  final actor = await request.extract(const Extension<AuthenticatedAdmin>());
  return Ok(actor.user);
}
