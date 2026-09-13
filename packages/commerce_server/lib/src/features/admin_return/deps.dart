import 'package:commerce_server/src/features/admin_return/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Persistence required by protected merchant return routes.
final class AdminReturnDeps {
  /// Creates the focused return dependency bundle.
  const AdminReturnDeps({required this.returns});

  /// Protected return-list reads.
  final AdminReturnRepository returns;
}

/// Extracts attached return dependencies or a configuration failure.
Future<Result<AdminReturnDeps, Rejection>> adminReturnDeps(Request request) =>
    stateOf<AdminReturnDeps>(request);
